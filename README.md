# ponytail-clients

A minimal, self-contained example of running **[Ponytail](https://github.com/DietrichGebert/ponytail)**
(lazy-senior-dev mode: YAGNI, stdlib first, smallest correct change) **always-on**
in three agents — **Claude Code**, **OpenCode**, and **KiloCode** — using each
agent's *native* injection point. No MCP server, no npm install.

## Why native, not the MCP server

Ponytail also ships an MCP server, but its own README says that's the fallback
"for MCP hosts whose only injection point is the prompt menu." MCP prompts/tools
are **user-invoked** — you'd have to call them every turn. All three agents here
have a native **always-on** mechanism, which is what you actually want for a
"mode" that should govern every response:

| Agent       | Mechanism                          | Always-on | Deps |
|-------------|------------------------------------|-----------|------|
| Claude Code | Skill **+** SessionStart hook      | yes       | none |
| OpenCode    | `instructions` file (rules)        | yes       | none |
| KiloCode    | `instructions` file (rules)        | yes       | none |

## Layout

```
ponytail.md                       Ponytail ruleset — shared by OpenCode + KiloCode
opencode.json                     OpenCode: instructions -> ponytail.md
kilo.jsonc                        KiloCode: instructions -> ponytail.md
.claude/
  settings.json                   Claude Code: SessionStart hook (injects every session)
  skills/ponytail/SKILL.md        Claude Code skill (the richer rendering; also read by the hook)
  hooks/                          the hook's runtime (vendored from upstream, unmodified)
    ponytail-activate.js          SessionStart entry — emits the ruleset to stdout
    ponytail-instructions.js      builds the ruleset text from SKILL.md
    ponytail-config.js            mode resolution (env / config file)
    ponytail-runtime.js           hook I/O helpers
```

`SKILL.md` does double duty: Claude Code auto-loads it as a **skill**, and the
**hook** reads the same file (`../skills/ponytail/SKILL.md`) — one source, no copy.

## Setup & verify

### Claude Code
Already wired by `.claude/settings.json` + `.claude/skills/`. Just open this repo
with Claude Code. The skill is available as `/ponytail`, and the SessionStart
hook injects the ruleset every session.

Verify the hook emits the ruleset (this is exactly what Claude Code runs):
```bash
CLAUDE_PROJECT_DIR="$PWD" node .claude/hooks/ponytail-activate.js
# -> "PONYTAIL MODE ACTIVE — level: full" followed by the ruleset
```
> Windows: use the PowerShell hook form from upstream
> (`hooks/ponytail-statusline.ps1` / `commandWindows`). This example keeps the
> POSIX `command` only.

### OpenCode
`opencode.json` lists `./ponytail.md` under `instructions`, so OpenCode loads it
into context for every session in this project. Open the repo with OpenCode — no
extra steps.

### KiloCode
`kilo.jsonc` lists `./ponytail.md` under `instructions`. Open the repo in
KiloCode. If your KiloCode version predates `kilo.jsonc`, instead create
`.kilocode/rules/ponytail.md` (a copy of `ponytail.md`) — KiloCode auto-loads
anything in `.kilocode/rules/`.

## Switching intensity (lite / full / ultra)

Mode resolves the same way everywhere (the vendored `ponytail-config.js`):

1. `PONYTAIL_DEFAULT_MODE` env var, e.g. `export PONYTAIL_DEFAULT_MODE=ultra`
2. `~/.config/ponytail/config.json` → `{ "defaultMode": "ultra" }`
3. default: `full`

`full` is the default. The `ponytail.md` rules file is intensity-agnostic prose;
the Claude hook filters `SKILL.md` to the active level.

```bash
PONYTAIL_DEFAULT_MODE=ultra CLAUDE_PROJECT_DIR="$PWD" node .claude/hooks/ponytail-activate.js | head -1
# -> PONYTAIL MODE ACTIVE — level: ultra
```

## Attribution

Ponytail is by [Dietrich Gebert](https://github.com/DietrichGebert)
([DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)), MIT.
The files under `.claude/hooks/`, `.claude/skills/`, and `ponytail.md` are
vendored from that repo unmodified. See `LICENSE`.
