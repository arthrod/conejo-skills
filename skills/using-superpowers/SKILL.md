---
name: using-superpowers
description: Use when starting any conversation - establishes how to find and use skills, requiring skill invocation before ANY response including clarifying questions
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## The Rule

**Invoke relevant or requested skills BEFORE any response or action** — including clarifying questions, exploring the codebase, or checking files. If it turns out wrong for the situation, you don't have to use it.

**Before entering plan mode:** if you haven't already brainstormed, invoke the brainstorming skill first.

Then announce "Using [skill] to [purpose]" and follow the skill exactly. If it has a checklist, create a todo per item.

## Skill Priority

When multiple skills apply, process skills come first — they set the approach, then implementation skills (frontend-design, etc.) carry it out. Brainstorming and systematic-debugging are Superpowers' most common process skills, but the rule holds for any of them.

- "Let's build X" → superpowers:brainstorming first, then implementation skills.
- "Fix this bug" → superpowers:systematic-debugging first, then domain skills.

## Red Flags

These thoughts mean STOP—you're rationalizing:

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "I can check git/files quickly" | Files lack conversation context. Check for skills. |
| "Let me gather information first" | Skills tell you HOW to gather information. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "This doesn't count as a task" | Action = task. Check for skills. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This feels productive" | Undisciplined action wastes time. Skills prevent this. |
| "I know what that means" | Knowing the concept ≠ using the skill. Invoke it. |

## Platform Adaptation

If your harness appears here, read its reference file for special instructions:

- Claude Code: `references/claude-code-tools.md`
- Codex: `references/codex-tools.md`
- Pi: `references/pi-tools.md`
- Antigravity: `references/antigravity-tools.md`
- Hermes Agent: `references/hermes-tools.md`
- Muse: `references/muse-tools.md`

## User Instructions

User instructions (CLAUDE.md, AGENTS.md, GEMINI.md, etc, direct requests) take precedence over skills, which in turn override default behavior. Only skip skill workflows or instructions when your human partner has explicitly told you to.

<!-- vendored:start -->

## Source

Vendored from [`obra/superpowers`](https://github.com/obra/superpowers/tree/v7.0.2/skills/using-superpowers) **v7.0.2** (`22f0b46`) on 2026-11-06.
Refresh with `./scripts/refresh-superpowers.sh` from the conejo-skills repo — the `<!-- conejo -->` block below is re-applied automatically; upstream text above it is left verbatim.

<!-- vendored:end -->

<!-- conejo:start -->

## Conejo additions (arthrod's bundle)

- **Names.** In this bundle `superpowers:<name>` resolves as `<name>` (or
  `arthrod-skills:<name>`). Invoke the bare name.
- **Routing.** Any coding, research-code, PR, or debugging task starts at [[conejo]] —
  it routes to conejo-code / conejo-frontend / conejo-merge / conejo-debug and carries
  the non-negotiables (red-green TDD, acceptance criteria with independent measurers,
  stacked PRs via `gh stack`, other-corpus reviews, CI wait only on the last task,
  one-by-one PR replies).
- **Doctrines are authored once** in `conejo-code/references/`:
  `agent-dispatch.md` (which model CLIs exist, how to list and pick models),
  `acceptance-criteria.md`, `stacked-prs-and-ci.md`, `testing-doctrine.md`. The
  superpowers skills below point at them from their own `conejo` blocks; read the
  doctrine when the block says so.
- **User instructions still win.** `~/.claude/CLAUDE.md` carries Arthur's stack
  preference (pnpm, uv, pyrefly, oxlint, oxfmt, vite, vitest, astro, cargo-nextest)
  and the most-important rule: say bluntly when his instruction is wrong, never
  silently deviate.

<!-- conejo:end -->
