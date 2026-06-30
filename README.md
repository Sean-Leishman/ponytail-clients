# ponytail-clients

[![upstream: DietrichGebert/ponytail](https://img.shields.io/badge/upstream-DietrichGebert%2Fponytail-111111?style=flat-square&logo=github)](https://github.com/DietrichGebert/ponytail)

A minimal, **Claude-Code-only** port of **[Ponytail](https://github.com/DietrichGebert/ponytail)**
(lazy-senior-dev mode: YAGNI, stdlib first, smallest correct change). Each upstream
ability is a **native Claude skill** — no MCP server, no runtime JS, no build step.

## What's here

Six skills under `.claude/skills/`, copied verbatim from upstream:

| Skill | Invoke | What it does |
|-------|--------|--------------|
| **ponytail** | always-on + `/ponytail` | The lazy-senior-dev mode. Governs every response. |
| **ponytail-review** | `/ponytail-review` | Review a diff for over-engineering: what to delete. |
| **ponytail-audit** | `/ponytail-audit` | Whole-repo bloat audit, ranked. |
| **ponytail-debt** | `/ponytail-debt` | Harvest `ponytail:` shortcut comments into a ledger. |
| **ponytail-gain** | `/ponytail-gain` | Measured-impact scoreboard. |
| **ponytail-help** | `/ponytail-help` | Quick-reference card. |

Claude Code auto-discovers all six as skills. The main `ponytail` skill is also
kept **always-on** by a one-line `SessionStart` hook that just emits its body —
that's the whole "runtime":

```
.claude/
  settings.json                 SessionStart -> cat skills/ponytail/SKILL.md
  skills/<name>/SKILL.md         the six skills (native, invoke-on-demand)
```

No `.js`, no shared script — the single-script machinery the old layout needed
to fake always-on across multiple agents is gone. Native skills + one `cat`.

## Use it

**This repo only:** open it with Claude Code. The five `/ponytail-*` skills are
available immediately; the main mode is injected every session by the hook.

Verify the hook emits the ruleset (exactly what Claude Code runs):
```bash
CLAUDE_PROJECT_DIR="$PWD" sh -c 'cat "$CLAUDE_PROJECT_DIR/.claude/skills/ponytail/SKILL.md"' | head -1
# -> "name: ponytail"  (the always-on skill body follows)
```

**Every project:** install into your user config (`~/.claude`):
```bash
./install.sh
```
Idempotent, backs up `settings.json` (`.bak`) before editing. Requires `node`
only for that one settings merge.

> Prefer the upstream-maintained Claude Code plugin (with statusline, intensity
> switching, and other agents)? `/plugin marketplace add DietrichGebert/ponytail`
> then `/plugin install ponytail@ponytail`.

## Switching intensity

The `ponytail` skill ships `lite` / `full` / `ultra` levels (full is default).
Switch in-session: `/ponytail lite|full|ultra`. This minimal port doesn't carry
the upstream env/config-file mode resolution — for that, use the plugin above.

## Attribution

Ponytail is by [Dietrich Gebert](https://github.com/DietrichGebert)
([DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)), MIT.
The skills under `.claude/skills/` are vendored from that repo unmodified. See
`LICENSE`.
