#!/usr/bin/env bash
#
# Install Ponytail globally for Claude Code — active in every project, not just
# this repo. Copies the six skills to ~/.claude/skills and wires a SessionStart
# hook that keeps the main `ponytail` skill always-on.
#
# Idempotent — safe to re-run. Backs up (.bak) settings.json before editing.
# Requires: node (only for the one-time settings.json merge).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
log() { printf '\033[1;34m::\033[0m %s\n' "$*"; }

command -v node >/dev/null || { echo "node is required for the settings.json merge" >&2; exit 1; }

log "Skills -> $CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR/skills"
cp -R "$REPO/.claude/skills/." "$CLAUDE_DIR/skills/"

log "SessionStart hook -> $CLAUDE_DIR/settings.json"
node - "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/skills/ponytail/SKILL.md" <<'NODE'
const fs = require('fs');
const [file, skill] = process.argv.slice(2);
let s = {}; try { s = JSON.parse(fs.readFileSync(file, 'utf8')); } catch (e) {}
s.hooks = s.hooks || {};
s.hooks.SessionStart = s.hooks.SessionStart || [];
if (JSON.stringify(s.hooks.SessionStart).includes('skills/ponytail/SKILL.md')) {
  console.log('  hook already present'); process.exit(0);
}
if (fs.existsSync(file)) fs.copyFileSync(file, file + '.bak');
s.hooks.SessionStart.push({
  matcher: 'startup|resume|clear|compact',
  hooks: [{ type: 'command', command: `cat "${skill}"; exit 0`, timeout: 5 }],
});
fs.writeFileSync(file, JSON.stringify(s, null, 2));
console.log('  added SessionStart hook');
NODE

log "Done. The six /ponytail skills are global; ponytail mode is always-on every session."
