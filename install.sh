#!/usr/bin/env bash
#
# Install Ponytail globally — active in every project, not just this repo.
#   - Claude Code: skill + SessionStart hook + statusline  (-> ~/.claude)
#   - OpenCode:    instructions entry                       (-> ~/.config/opencode/opencode.json)
#   - KiloCode:    instructions entry                       (-> ~/.config/kilo/kilo.jsonc)
#
# Idempotent — safe to re-run. Backs up (.bak) any settings/config file it edits.
# Usage:  ./install.sh            # all three
#         ./install.sh claude     # only the named clients (claude|opencode|kilo)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
log()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

command -v node >/dev/null || { warn "node is required (the hook + JSON merge need it)"; exit 1; }

# Which clients to install (default: all).
want() { [ "$#" -eq 0 ] && return 1; printf '%s\n' "$@" | grep -qx "$1"; }
TARGETS=("$@")
do_client() { [ "${#TARGETS[@]}" -eq 0 ] || want "$1" "${TARGETS[@]}"; }

# Shared ruleset location that OpenCode + KiloCode point at.
RULES="$CFG/ponytail/ponytail.md"

# Add a path to a JSON/JSONC config's "instructions" array, idempotently.
add_instruction() {
  node - "$1" "$2" <<'NODE'
const fs = require('fs');
const [file, add] = process.argv.slice(2);
let raw = ''; try { raw = fs.readFileSync(file, 'utf8'); } catch (e) {}
let obj = {};
if (raw.trim()) {
  try { obj = JSON.parse(raw.replace(/^\s*\/\/.*$/gm, '')); } // tolerate // comments (jsonc)
  catch (e) { console.error('  ! could not parse ' + file + ', leaving it untouched'); process.exit(0); }
}
obj.instructions = Array.isArray(obj.instructions) ? obj.instructions : [];
if (obj.instructions.includes(add)) { console.log('  already present in ' + file); process.exit(0); }
if (raw) fs.copyFileSync(file, file + '.bak');
obj.instructions.push(add);
fs.writeFileSync(file, JSON.stringify(obj, null, 2) + '\n');
console.log('  added instructions entry to ' + file);
NODE
}

# --- Claude Code -----------------------------------------------------------
if do_client claude; then
  CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  log "Claude Code -> $CLAUDE_DIR"
  mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/hooks"
  cp -R "$REPO/.claude/skills/ponytail" "$CLAUDE_DIR/skills/"
  cp "$REPO/.claude/hooks/"ponytail-* "$CLAUDE_DIR/hooks/"
  chmod +x "$CLAUDE_DIR/hooks/ponytail-statusline.sh" 2>/dev/null || true
  # Merge the SessionStart hook into settings.json (absolute path, since it's global).
  node - "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/hooks/ponytail-activate.js" <<'NODE'
const fs = require('fs');
const [file, hook] = process.argv.slice(2);
let s = {}; try { s = JSON.parse(fs.readFileSync(file, 'utf8')); } catch (e) {}
s.hooks = s.hooks || {};
s.hooks.SessionStart = s.hooks.SessionStart || [];
if (JSON.stringify(s.hooks.SessionStart).includes('ponytail-activate')) {
  console.log('  SessionStart hook already present');
} else {
  if (fs.existsSync(file)) fs.copyFileSync(file, file + '.bak');
  s.hooks.SessionStart.push({
    matcher: 'startup|resume|clear|compact',
    hooks: [{ type: 'command', command: `node "${hook}"; exit 0`, timeout: 5 }],
  });
  fs.writeFileSync(file, JSON.stringify(s, null, 2));
  console.log('  added SessionStart hook to ' + file);
}
NODE
fi

# --- OpenCode + KiloCode (point at the shared ruleset) ---------------------
if do_client opencode || do_client kilo; then
  mkdir -p "$(dirname "$RULES")"
  cp "$REPO/ponytail.md" "$RULES"
  log "Ruleset -> $RULES"
fi
if do_client opencode; then
  log "OpenCode -> $CFG/opencode/opencode.json"
  mkdir -p "$CFG/opencode"
  add_instruction "$CFG/opencode/opencode.json" "$RULES"
fi
if do_client kilo; then
  log "KiloCode -> $CFG/kilo/kilo.jsonc"
  mkdir -p "$CFG/kilo"
  add_instruction "$CFG/kilo/kilo.jsonc" "$RULES"
fi

log "Done. Ponytail is now global. Set a default level with: export PONYTAIL_DEFAULT_MODE=ultra"
