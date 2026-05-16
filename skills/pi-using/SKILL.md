---
name: pi-using
description: Using the Pi terminal agent — workspace setup, sessions, /commands, compaction, settings.json/AGENTS.md, skill discovery, providers/models, plus theme/keybinding/prompt customization (SYSTEM.md, APPEND_SYSTEM.md, settings.json, keybindings.json). Use for any "how do I configure/run Pi" question.
---

# Pi — Using & Customizing

Two halves of "using pi":

| Concern | Section |
|---|---|
| Workspace, sessions, /commands, providers, models, tmux/Termux/Windows | [Workspace](#workspace) |
| Themes, keybindings, prompt templates, SYSTEM.md overrides | [Customization](#customization) |

---

# Workspace


# Pi CLI and workspace

Answer only from `pi-mono/` sources listed below. If something is not in the tree, say you cannot confirm from the corpus.

## Grounding (read in order)

1. `pi-mono/packages/coding-agent/README.md` — product surface, commands, customization.
2. `pi-mono/packages/coding-agent/docs/skills.md` — skill locations, `/skill:name`, frontmatter, collisions.
3. `pi-mono/packages/coding-agent/docs/settings.md` — settings locations and keys.
4. `pi-mono/AGENTS.md` — maintainer rules when editing pi-mono itself.
5. `pi-mono/packages/coding-agent/docs/compaction.md` — auto-compaction triggers, cut-point algorithm, `reserveTokens`/`keepRecentTokens` settings, chained compactions, branch summarization.
6. `pi-mono/packages/coding-agent/docs/session.md` — JSONL session format, `~/.pi/agent/sessions/` paths, entry types (message, compaction, branch_summary, custom, label), `buildSessionContext()` assembly.
7. `pi-mono/packages/coding-agent/docs/tree.md` — `/tree` vs `/fork`, branch navigation, summarization options, tree UI keybindings.
8. `pi-mono/packages/coding-agent/docs/providers.md` — subscription OAuth (`/login`), API-key providers, `auth.json`, env-var credential table, cloud providers (Azure, Bedrock, Vertex).
9. `pi-mono/packages/coding-agent/docs/models.md` — `models.json` for Ollama/vLLM/LM Studio, `compat` flags, `modelOverrides`, provider-level config.
10. `pi-mono/packages/coding-agent/docs/custom-provider.md` — extension-registered providers via `registerProvider()`, OAuth flows, proxy patterns.
11. `pi-mono/packages/coding-agent/docs/terminal-setup.md` — Kitty keyboard protocol, Ghostty/iTerm/terminal keybinding caveats.
12. `pi-mono/packages/coding-agent/docs/tmux.md` — tmux `extended-keys` / `csi-u` so modified keys work inside pi.
13. `pi-mono/packages/coding-agent/docs/windows.md` — Windows bash discovery order (`shellPath` setting, Git Bash, PATH).
14. `pi-mono/packages/coding-agent/docs/termux.md` — running pi on Android via Termux (install, clipboard, storage).
15. `pi-mono/packages/coding-agent/docs/shell-aliases.md` — non-interactive bash and `shellCommandPrefix` to expand aliases from dotfiles.
16. `pi-mono/packages/coding-agent/docs/development.md` — local development setup, `pi-test.sh`, fork/rebrand via `piConfig`, test commands.
17. Implementation (for precedence and prompt wiring):
    - `pi-mono/packages/coding-agent/src/core/package-manager.ts` — `resourcePrecedenceRank` comment block (ordering intent).
    - `pi-mono/packages/coding-agent/src/core/resource-loader.ts` — `reload()` skill path merge (`cliEnabledSkills`, `enabledSkills`, `additionalSkillPaths`).
    - `pi-mono/packages/coding-agent/src/core/skills.ts` — `loadSkills`, `formatSkillsForPrompt`, name collision handling.
    - `pi-mono/packages/coding-agent/src/core/system-prompt.ts` — default harness text and `hasRead` gate for skills XML.
    - `pi-mono/packages/coding-agent/src/core/agent-session.ts` — `_expandSkillCommand` inlines `/skill:name` body.
18. `pi-mono/packages/coding-agent/README.md` §Editor — `@` fuzzy-search, Tab completion, Ctrl+V image paste, `!`/`!!` bash commands.
19. `pi-mono/packages/coding-agent/README.md` §Message Queue — steering (Enter) vs follow-up (Alt+Enter), `steeringMode`/`followUpMode`/`transport` settings.
20. `pi-mono/packages/coding-agent/README.md` §Modes, §CLI Reference — interactive, `-p`/`--print`, `--mode json`, `--mode rpc`, piped stdin.
21. `pi-mono/packages/coding-agent/README.md` §CLI Reference — full flag table, `@files`, `--tools`, `--no-tools`, `--no-extensions`, `--no-skills`, `--no-prompt-templates`, `--no-themes`, resource control.
22. `pi-mono/packages/coding-agent/README.md` §Environment Variables — `PI_CODING_AGENT_DIR`, `PI_PACKAGE_DIR`, `PI_SKIP_VERSION_CHECK`, `PI_CACHE_RETENTION`, `VISUAL`/`EDITOR`.
23. `pi-mono/packages/coding-agent/README.md` §Philosophy — what core intentionally omits (no MCP, no sub-agents, no permission popups, no plan mode, no built-in todos, no background bash); everything buildable via extensions.

## Invariants

- Skill **name collisions**: first registered name wins; later paths emit collision diagnostics (`pi-mono/packages/coding-agent/src/core/skills.ts`). **Path order** is assembled in `resource-loader.ts` then fed to `loadSkills`.
- Resource **precedence rank** (lower = earlier in sorted package-manager lists): project local (0), project auto (1), user local (2), user auto (3), package (4) — `pi-mono/packages/coding-agent/src/core/package-manager.ts`.
- Merged skill paths: `mergePaths([...cliEnabledSkills, ...enabledSkills], additionalSkillPaths)` — CLI paths appear before package-manager lists; see `pi-mono/packages/coding-agent/src/core/resource-loader.ts`.
- `<available_skills>` is appended to the system prompt only when the **`read` tool** is among selected tools — `pi-mono/packages/coding-agent/src/core/system-prompt.ts`.
- Default system prompt already points models at packaged docs paths (`readmePath`, `docsPath`, examples) — `pi-mono/packages/coding-agent/src/core/system-prompt.ts`. This skill adds **workspace and precedence** detail, not a duplicate README.
- Session format version is v3 (tree-based `id`/`parentId`); `buildSessionContext` assembles compaction summary + branch summary + messages after the compaction point — see `pi-mono/packages/coding-agent/docs/session.md`.
- Compaction cut-point selection avoids splitting tool results; `firstKeptEntryId` links chained compactions — see `pi-mono/packages/coding-agent/docs/compaction.md`.
- Credential resolution order: `--api-key` flag > `auth.json` > environment variables > `models.json` custom keys — see `pi-mono/packages/coding-agent/docs/providers.md`.
- **SYSTEM.md / APPEND_SYSTEM.md**: Replace the default system prompt with `.pi/SYSTEM.md` (project) or `~/.pi/agent/SYSTEM.md` (global). Append without replacing via `APPEND_SYSTEM.md` at the same locations. Context files and skills are still appended after override — `pi-mono/packages/coding-agent/README.md` §Context Files.
- **Message queue**: Enter queues a *steering* message (delivered between tool calls); Alt+Enter queues a *follow-up* (delivered after the agent finishes all work). Escape aborts; Alt+Up retrieves queued messages. Settings: `steeringMode` and `followUpMode` (`"one-at-a-time"` default vs `"all"`); `transport` (`"sse"`, `"websocket"`, `"auto"`) — `pi-mono/packages/coding-agent/README.md` §Message Queue, `pi-mono/packages/coding-agent/docs/settings.md`.
- **Built-in tools**: Default four: `read`, `bash`, `edit`, `write`. Additional available: `grep`, `find`, `ls`. Control via `--tools <list>` (e.g., `--tools read,grep,find,ls` for read-only) and `--no-tools` (disables all built-in; extension tools still work) — `pi-mono/packages/coding-agent/README.md` §Tool Options.
- **Editor features**: `@` fuzzy-searches project files; Tab completes paths; Ctrl+V pastes images (Alt+V on Windows); `!command` runs and sends output to LLM; `!!command` runs without sending — `pi-mono/packages/coding-agent/README.md` §Editor, `pi-mono/packages/coding-agent/docs/keybindings.md`.
- **Print mode**: `-p`/`--print` for non-interactive stdout output. Reads piped stdin: `cat README.md | pi -p "Summarize"`. Combine with `--mode json` for JSON-line output — `pi-mono/packages/coding-agent/README.md` §Modes.
- **CLI session flags**: `-c`/`--continue` (most recent session), `-r`/`--resume` (browse/select), `--session <path>` (specific file or partial UUID), `--fork <path>` (fork from CLI), `--no-session` (ephemeral), `--session-dir <dir>` (custom storage) — `pi-mono/packages/coding-agent/README.md` §Session Options.
- **@files CLI arguments**: Prefix files with `@` on CLI: `pi @screenshot.png "What's in this?"`, `pi @code.ts @test.ts "Review"`. Included as part of the initial message — `pi-mono/packages/coding-agent/README.md` §File Arguments.
- **Resource control flags**: `--no-extensions`, `--no-skills`, `--no-prompt-templates`, `--no-themes` disable auto-discovery. `-e`/`--extension`, `--skill`, `--prompt-template`, `--theme` for explicit loading. Combine `--no-*` with explicit flags for exact control (e.g., `--no-extensions -e ./my-ext.ts`) — `pi-mono/packages/coding-agent/README.md` §Resource Options.
- **Model shorthand**: `--model provider/id` (e.g., `openai/gpt-4o`), `--model name:thinking` (e.g., `sonnet:high`), `--models <patterns>` for Ctrl+P cycling, `--list-models` — `pi-mono/packages/coding-agent/README.md` §Model Options.
- **Slash commands** (full interactive list): `/login`, `/logout`, `/model`, `/scoped-models`, `/settings`, `/resume`, `/new`, `/name`, `/session`, `/tree`, `/fork`, `/compact`, `/copy`, `/export`, `/share`, `/reload`, `/hotkeys`, `/changelog`, `/quit`. Extensions register custom commands; skills expose `/skill:name`; prompt templates expand via `/templatename` — `pi-mono/packages/coding-agent/README.md` §Commands.
- **Environment variables**: `PI_CODING_AGENT_DIR` (override config dir), `PI_PACKAGE_DIR` (override package dir), `PI_SKIP_VERSION_CHECK`, `PI_CACHE_RETENTION` (`long` for extended prompt cache), `VISUAL`/`EDITOR` (external editor for Ctrl+G) — `pi-mono/packages/coding-agent/README.md` §Environment Variables.
- **Philosophy** (what pi intentionally omits): No MCP (use CLI tools or extensions), no sub-agents (use tmux or extensions), no permission popups (use container or extension), no plan mode (use files or extension), no built-in to-dos, no background bash (use tmux). Everything is buildable via extensions — `pi-mono/packages/coding-agent/README.md` §Philosophy.

## Workflows

- **Find where a skill is discovered**: Walk `docs/skills.md` locations, then cross-check `package-manager.ts` auto-discovery and `settings.json` `skills` arrays.
- **Explain shadowing**: Combine `resourcePrecedenceRank` ordering with `mergePaths` / `loadSkills` "first name wins" using file citations only.
- **User forced load**: `/skill:name` expansion — `pi-mono/packages/coding-agent/src/core/agent-session.ts`.
- **Debug compaction**: Read `compaction.md` algorithm; check `reserveTokens` / `keepRecentTokens` in `settings.json`; trace chained compactions via `firstKeptEntryId`.
- **Add custom model**: Follow `models.md` minimal example for Ollama/vLLM/LM Studio; check `compat` flags for non-standard OpenAI-compatible servers.
- **Session archaeology**: Parse `.jsonl` using the switch example in `session.md`; navigate branches via `/tree` per `tree.md`.
- **Configure providers**: Check `providers.md` for subscription OAuth (`/login`) vs API-key flow; see `auth.json` layout and env-var table.
- **Platform setup**: For tmux, read `tmux.md` (`extended-keys`); for Windows, `windows.md` (`shellPath`); for Android, `termux.md`; for terminal quirks, `terminal-setup.md`.
- **Shell aliases**: Read `shell-aliases.md` for `shellCommandPrefix` to make pi's bash tool see dotfile aliases.
- **Develop pi from source**: Read `development.md` for clone/build/test and `pi-test.sh` runner.
- **Control tools**: Use `--tools read,grep,find,ls` for read-only mode; `--no-tools` to disable all built-in tools (extension tools still work). Default is `read,bash,edit,write`.
- **Non-interactive mode**: `pi -p "prompt"` or `cat file | pi -p "Summarize"` for CI/scripts. Combine with `--mode json` for machine-readable JSON-line output.
- **Custom system prompt**: Place `.pi/SYSTEM.md` in a project or `~/.pi/agent/SYSTEM.md` globally to replace the default prompt. Use `APPEND_SYSTEM.md` at the same locations to append without replacing.

## Anti-patterns

- Do not invent MCP or sub-agent behavior as "built into core"; check `pi-mono/packages/coding-agent/README.md` philosophy section for what core omits.
- Do not claim exact merge behavior without citing `resource-loader.ts` and `skills.ts`.
- Do not describe compaction cut-point behavior from memory; cite `compaction.md` algorithm section.
- Do not guess credential resolution order; cite `providers.md` for the exact precedence.

---

# Customization


# Pi Customization

## Grounding

1. `pi-mono/packages/coding-agent/docs/themes.md` — theme JSON format (`name`, optional `vars`, required 51 `colors` tokens), locations (`~/.pi/agent/themes/*.json`, `.pi/themes/*.json`, packages, settings, CLI `--theme`), hot reload, color value formats.
2. `pi-mono/packages/coding-agent/docs/keybindings.md` — customization via `~/.pi/agent/keybindings.json`, namespaced action IDs (`tui.input.submit`, `tui.editor.cursorUp`, `app.interrupt`, etc.), key format (`modifier+key`), full action tables.
3. `pi-mono/packages/coding-agent/docs/prompt-templates.md` — Markdown snippets invoked via `/name`, locations (`~/.pi/agent/prompts/*.md`, `.pi/prompts/*.md`, packages), positional arguments (`$1`, `$2`, `$@`, `${@:N}`), YAML frontmatter with optional `description`.
4. `pi-mono/packages/coding-agent/README.md` — Context Files section for `.pi/SYSTEM.md`, `~/.pi/agent/SYSTEM.md`, and `APPEND_SYSTEM.md`.
5. `pi-mono/packages/coding-agent/docs/settings.md` — the overall `settings.json` structure for tying these together.

## Invariants

- **Theme Format**: Themes define `name` (required, unique), optional `vars` for reusable color aliases, and all 51 `colors` tokens. There is no `type`, `ui`, `syntax`, or `borders` top-level key — everything is under `colors`. Loaded from `~/.pi/agent/themes/*.json` (global) and `.pi/themes/*.json` (project).
- **Keybinding Config**: Keybindings are configured in `~/.pi/agent/keybindings.json` (not `settings.json`). IDs are namespaced: `tui.input.submit` (submit), `tui.editor.cursorUp`, `app.interrupt`, etc. Run `/reload` to apply changes without restarting.
- **Prompt Template Arguments**: Templates use `$1`, `$2`, `$@`, `${@:N}` positional syntax — not `{variable}` or `<include>`. The filename (minus `.md`) becomes the `/name` command.
- **System Prompt Override**: Replace the default system prompt with `.pi/SYSTEM.md` (project) or `~/.pi/agent/SYSTEM.md` (global). Use `APPEND_SYSTEM.md` to append instead of replace. Context files and skills are still appended after the override.

## Workflows

- **Create a Theme**: Copy `dark.json` from `packages/coding-agent/src/modes/interactive/theme/`, customize color values under the `colors` key, place it in `~/.pi/agent/themes/`, and select via `/settings` or `pi --theme <name>`.
- **Override Keys**: Create or edit `~/.pi/agent/keybindings.json` mapping action IDs to key arrays (e.g., `"tui.input.submit": ["ctrl+enter"]`). Run `/reload` to apply.
- **Create a Prompt Template**: Write a `.md` file in `~/.pi/agent/prompts/` with optional YAML frontmatter (`description`); use `$1`, `$@` for arguments. Invoke with `/filename` in the editor.
- **Override the System Prompt**: Create `.pi/SYSTEM.md` in the project or `~/.pi/agent/SYSTEM.md` globally to replace the default system prompt. Use `APPEND_SYSTEM.md` at the same locations if you want to append custom instructions instead.

## Anti-patterns

- Do not hardcode keybindings into agent component source code — use the configurable namespaces from `keybindings.md`.
- Do not put keybindings in `settings.json` — keybindings have their own file (`~/.pi/agent/keybindings.json`).
- Do not use `{variable}` or `<include src="...">` syntax in prompt templates — the actual syntax is `$1`, `$@`, `${@:N}`.

<!-- cross-ref:start -->

## See also (related skills — Pi family)

If your issue relates to:
- **extending Pi: TypeScript extensions, npm packages, JSON-RPC SDK, pi_agent_rust internals** — check `pi-extending` if appropriate.

<!-- cross-ref:end -->

