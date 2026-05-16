---
name: pi-extending
description: Building & extending Pi — authoring TypeScript extensions (ExtensionAPI, registerTool, registerProvider, /commands, UI hooks), publishing as npm/git packages (pi-package), embedding via JSON-RPC mode (--mode rpc/json, JSONL framing, AgentSession SDK), and developing inside the pi_agent_rust repo. Use for any "how do I build a Pi extension/package/SDK client" question.
---

# Pi — Extending & Embedding

Four ways to build on top of Pi:

| Concern | Section |
|---|---|
| Authoring TypeScript extensions (tools, commands, hooks, providers) | [Extension authoring](#extension-authoring) |
| Distributing extensions/skills via npm or git | [Package authoring](#package-authoring) |
| Embedding pi or speaking the JSON-RPC protocol | [RPC + SDK](#rpc--sdk) |
| Working inside the pi_agent_rust repo | [pi_agent_rust internals](#pi_agent_rust-internals) |

---

# Extension Authoring


# Pi extension authoring

Ground every answer in `pi-mono/` files below.

## Grounding

1. `pi-mono/packages/coding-agent/docs/extensions.md` — capabilities, lifecycle, patterns.
2. `pi-mono/packages/coding-agent/examples/extensions/README.md` — runnable examples index.
3. `pi-mono/packages/coding-agent/src/core/resource-loader.ts` — `extendResources()` appends paths via `mergePaths` after existing `lastSkillPaths` (late paths lose name collisions to earlier ones unless names differ).
4. `pi-mono/packages/coding-agent/src/core/agent-session.ts` — extension commands vs queued prompts; skill expansion hooks.
5. `pi-mono/packages/coding-agent/docs/tui.md` — extension TUI component integration with `@mariozechner/pi-tui`: `Component` rendering contract, overlay patterns, input handling in extension context.
6. `pi-mono/packages/coding-agent/docs/custom-provider.md` — `registerProvider()` for proxies, OAuth/SSO, custom APIs, and custom model definitions.

## Invariants

- Extensions can register tools, commands, themes, prompts, and extra skill paths; exact API surface is defined in docs and example modules — start from `docs/extensions.md`, not memory.
- Dynamic resource discovery patterns live under `pi-mono/packages/coding-agent/examples/extensions/` (e.g. `dynamic-resources/` listing in examples README).

## Workflows

- **New extension**: Read `docs/extensions.md`, clone the closest `examples/extensions/` template, then align with project `AGENTS.md` if working inside `pi-mono`.
- **Skills from extensions**: Trace `extendResources` + `mergePaths` in `resource-loader.ts` to explain ordering with user/project/package skills.
- **Extension TUI**: Read `docs/tui.md` for the `Component` rendering contract in extension context; combine with `pi-tui` skill for library-level APIs.
- **Custom providers via extension**: See `pi-mono/packages/coding-agent/docs/custom-provider.md` for `registerProvider()` OAuth flows and proxy patterns (grounded in `pi-cli-workspace`).

## Anti-patterns

- Do not assert MCP support in core; optional via extension (see coding-agent README philosophy).

---

# Package Authoring


# Pi package authoring

## Grounding

1. `pi-mono/packages/coding-agent/docs/packages.md` — manifest, install commands, layout.
2. `pi-mono/packages/coding-agent/README.md` — Pi Packages section (`pi install`, `package.json` `pi` key, keywords).
3. `pi-mono/packages/coding-agent/src/core/package-manager.ts` — `resourcePrecedenceRank` (package-origin resources sort after user/project).

## Invariants

- Packages integrate through the same resource resolution pipeline as local dirs; **package-origin** metadata ranks after user/project auto paths — see `resourcePrecedenceRank` in `pi-mono/packages/coding-agent/src/core/package-manager.ts`.
- Third-party packages execute code; skills can instruct arbitrary actions — security notes are first-party in `docs/packages.md` and coding-agent README.

## Workflows

- **Define a package**: Mirror the `package.json` example from `docs/packages.md` / README; verify conventional dirs (`skills/`, `extensions/`, etc.) against those docs.
- **Predict overrides**: Combine package-manager precedence with `loadSkills` “first name wins” (`pi-mono/packages/coding-agent/src/core/skills.ts`).

## Anti-patterns

- Do not invent CLI flags not documented in `docs/packages.md` / README.

---

# RPC + SDK


# Pi RPC and SDK integration

## Grounding

1. `pi-mono/packages/coding-agent/docs/rpc.md` — **Framing** section (LF-only record delimiter; `readline` incompatibility with U+2028/U+2029).
2. `pi-mono/packages/coding-agent/docs/sdk.md` — programmatic session patterns plus `createAgentSession`, `AgentSession`, `createAgentSessionRuntime`, `ModelRegistry.create()`, `AuthStorage.create()`, and `SessionManager.inMemory()`.
3. `pi-mono/packages/coding-agent/docs/json.md` — `--mode json` event stream: session header, `agent_*`/`turn_*`/`message_*`/`tool_execution_*` events, `jq` filtering examples.
4. `pi-mono/packages/coding-agent/src/modes/rpc/rpc-client.ts` — reference TypeScript client mentioned from `rpc.md` intro when applicable.
5. `pi-mono/packages/coding-agent/src/core/agent-session.ts` — API surface for in-process embedding (per `rpc.md` note to TypeScript users).

## Invariants

- Framing rules are normative text in `pi-mono/packages/coding-agent/docs/rpc.md`; quote or paraphrase strictly from that file when advising client implementers.
- Skill commands and prompt templates are expanded for RPC prompts per `rpc.md` **Input expansion** bullet under `prompt` command.
- `--mode json` is read-only observation (stdout events); `--mode rpc` is bidirectional control (stdin commands + stdout responses). Different use cases, same framing caveats for U+2028/U+2029.
- For TypeScript/Node embedding, `createAgentSession()` is the primary factory; it requires `sessionManager`, `authStorage`, and `modelRegistry`. For advanced multi-session hosting, use `createAgentSessionRuntime()` which returns `AgentSessionRuntime` with lower-level access to `agent`, `sessionManager`, `settingsManager`, `modelRegistry`, `extensions`, `bashExecutor`, `resourceLoader` — `pi-mono/packages/coding-agent/docs/sdk.md`.

## Workflows

- **Choose integration**: If user is on Node/TS, point to `rpc.md` recommendation to prefer `AgentSession` vs subprocess; cite the file’s opening **Note for Node.js/TypeScript users**.
- **Debug framing**: Re-read **Framing** section; do not suggest generic line readers as compliant.
- **JSON event stream**: For read-only observation of agent activity, point to `json.md` (`--mode json`); for bidirectional control, point to `rpc.md` (`--mode rpc`).
- **In-process embedding**: For TypeScript/Node users who don't need subprocess isolation, prefer `createAgentSession()` over `--mode rpc`. Import from `@mariozechner/pi-coding-agent`. See `pi-mono/packages/coding-agent/docs/sdk.md` and `pi-mono/packages/coding-agent/examples/sdk/`.

## Anti-patterns

- Do not describe delimiter behavior contradicting `rpc.md` (only `\n` as record delimiter; optional `\r` strip on input).

---

# pi_agent_rust internals


<!-- pi_agent_rust installer managed skill -->

# Pi Agent Rust

## Use This Skill When

- You are working inside `pi_agent_rust` and need the fastest path to safe, verified edits.
- You are touching provider/tool/session/extension behavior and need targeted triage.
- You are changing installer/uninstaller/skill install behavior and need deterministic safety checks.
- You need symptom-first debugging playbooks instead of ad-hoc command hunting.

## 60-Second Bootstrap

```bash
export CARGO_TARGET_DIR="/data/tmp/pi_agent_rust/${USER:-agent}"
export TMPDIR="/data/tmp/pi_agent_rust/${USER:-agent}/tmp"
mkdir -p "$TMPDIR"

rch exec -- cargo check --all-targets
rch exec -- cargo clippy --all-targets -- -D warnings
cargo fmt --check
bash tests/installer_regression.sh
```

## Symptom Router

| Symptom | First 3 Commands |
|---|---|
| Provider stream/tool-call regression | `cargo test provider_streaming -- --nocapture` ; `rg -n "stream|tool|delta|event|SSE" src/providers src/sse.rs` ; `cargo test conformance` |
| Session replay/index drift | `cargo test session -- --nocapture` ; `rg -n "Session|save|open|index|jsonl|sqlite" src/session.rs src/session_index.rs` ; `cargo test conformance` |
| Extension policy/runtime failure | `cargo test extension -- --nocapture` ; `rg -n "policy|hostcall|capability|quickjs|deny|allow" src/extensions.rs src/extensions_js.rs` ; `cargo test conformance` |
| Installer/uninstaller/skill issue | `bash tests/installer_regression.sh` ; `rg -n "AGENT_SKILL_STATUS|CHECKSUM_STATUS|SIGSTORE_STATUS|COMPLETIONS_STATUS" install.sh` ; `rg -n "managed skill|expected skill directory|PIAR_AGENT_SKILL" uninstall.sh` |
| Interactive vs RPC divergence | `cargo test e2e_rpc -- --nocapture` ; `rg -n "interactive|rpc|stdin|event|session" src/main.rs src/interactive.rs src/rpc.rs` ; `cargo test conformance` |

For deeper diagnosis, use `references/DEBUGGING-PLAYBOOKS.md`.

## Non-Negotiables

- Read `AGENTS.md` first, then follow it exactly.
- Do not delete files or run destructive git/filesystem commands.
- Keep edits in-place; avoid creating variant files for the same purpose.
- Use `main` semantics in docs/scripts; do not introduce `master`.
- Prefer `rg` for fast text recon and `ast-grep` for structural matching/refactors.
- Prefer `rch exec -- <cargo ...>` for heavy compile/test workloads.
- After substantive edits, run compile/lint/format gates and the smallest relevant regression slice.

## Core Workflow

- [ ] Recon: identify exact change surface and invariants.
- [ ] Implement: minimal, behavior-focused patch with explicit failure semantics.
- [ ] Validate: targeted tests first, broaden only as needed.
- [ ] Verify UX: error/status output is explicit, stable, and non-ambiguous.
- [ ] Sync docs: update `README.md` when flags/behavior/user guidance changed.

## Changed Files -> Required Tests

| Changed Files (examples) | Minimum Required Tests |
|---|---|
| `install.sh`, `uninstall.sh`, `.claude/skills/pi-agent-rust/**` | `bash -n install.sh uninstall.sh tests/installer_regression.sh` ; `shellcheck -x install.sh uninstall.sh tests/installer_regression.sh` ; `bash tests/installer_regression.sh` ; `bash scripts/skill-smoke.sh` |
| `src/providers/**`, `src/provider.rs`, `src/sse.rs` | `cargo test provider_streaming` ; `cargo test conformance` |
| `src/session.rs`, `src/session_index.rs`, `src/session_test.rs` | `cargo test session` ; `cargo test conformance` |
| `src/extensions.rs`, `src/extensions_js.rs` | `cargo test extension` ; `cargo test conformance` |
| `src/tools.rs` | `cargo test tools` ; `cargo test conformance` |
| `src/interactive.rs`, `src/rpc.rs`, `src/main.rs` | `cargo test e2e_rpc` ; `cargo test conformance` |

## Do Not Run Yet

Run these only after targeted repro + focused slice indicates need:

- Broad `cargo test` across entire workspace when a narrower slice already reproduces.
- Heavy multi-surface runs before confirming changed-file impact.
- Repeated full conformance loops while the core failing slice is still unstable.

## High-Value Commands

```bash
# Fast recon
git status --short
rg -n "install|uninstall|skill|checksum|sigstore|completion|provider|session|extension" \
  install.sh uninstall.sh README.md tests/installer_regression.sh src/

# Installer + skill safety gates
bash -n install.sh uninstall.sh tests/installer_regression.sh
shellcheck -x install.sh uninstall.sh tests/installer_regression.sh
bash tests/installer_regression.sh
bash scripts/skill-smoke.sh

# Rust gates
rch exec -- cargo check --all-targets
rch exec -- cargo clippy --all-targets -- -D warnings
cargo fmt --check
```

For an expanded command cookbook, see `references/COMMANDS.md`.
For deep incident triage, see `references/DEBUGGING-PLAYBOOKS.md`.

## Critical Files

- `src/main.rs`: CLI entry and mode dispatch.
- `src/agent.rs`: agent loop and tool iteration behavior.
- `src/provider.rs`: provider trait contract.
- `src/providers/`: provider implementations and factory wiring.
- `src/tools.rs`: built-in tools (`read`, `write`, `edit`, `bash`, `grep`, `find`, `ls`).
- `src/session.rs`: JSONL session persistence.
- `src/session_index.rs`: session index and metadata cache.
- `src/extensions.rs` + `src/extensions_js.rs`: extension policy and QuickJS bridge.
- `src/interactive.rs` + `src/rpc.rs`: TUI and RPC/stdin surfaces.
- `install.sh` + `uninstall.sh`: install lifecycle, migration, and skill management.
- `tests/installer_regression.sh`: installer regression harness.
- `scripts/skill-smoke.sh`: skill integrity + inline-sync validation.

## Known Footguns

- Custom artifact install paths without compatible release context can fall back incorrectly if not explicitly guarded.
- Skill status can become misleading on mixed outcomes unless partial/failure branches are explicit.
- Uninstall logic must enforce both marker checks and expected destination path shape.
- Installer progress/status text should stay on stderr when stdout is used for data plumbing.
- Bundled skill and inline fallback can silently drift unless explicitly checked.

## Patch Patterns

### Pattern 1: Mixed Outcome Status Clarity

```bash
# BEFORE: everything collapsed into "skipped custom"
if [ "$skipped_custom" -ge 1 ]; then
  AGENT_SKILL_STATUS="skipped (existing custom skill)"
fi

# AFTER: distinguish custom-skip from write failure
if [ "$skipped_custom" -ge 1 ] && [ "$failed_writes" -ge 1 ]; then
  AGENT_SKILL_STATUS="partial (custom skill kept; other install failed)"
elif [ "$skipped_custom" -ge 1 ]; then
  AGENT_SKILL_STATUS="skipped (existing custom skill)"
fi
```

### Pattern 2: Safe Skill Replacement

```bash
# BEFORE: remove destination before validating copy result
rm -rf "$destination"
cp "$source" "$destination/SKILL.md"

# AFTER: stage then atomically move into place
staged="$(mktemp -d ...)"
cp "$source" "$staged/SKILL.md"
mv "$staged" "$destination"
```

## Failure Triage

- Installer summary/status mismatch:
  trace `AGENT_SKILL_STATUS`, `CHECKSUM_STATUS`, and `COMPLETIONS_STATUS` in `install.sh`.
- Install/uninstall safety concern:
  verify marker checks and expected destination guards in both scripts.
- Provider/session/extension regressions:
  use symptom router, then follow `references/DEBUGGING-PLAYBOOKS.md`.
- Docs drift:
  ensure `README.md` flags/examples match current installer behavior.

## Done Criteria

- Changed-file matrix minimum tests passed.
- Compile/lint/format checks passed for touched surfaces.
- Installer/skill changes pass `tests/installer_regression.sh` and `scripts/skill-smoke.sh`.
- Behavior is explicit on failure paths; no silent fallback surprises.
- Skill docs and inline fallback remain aligned and current.

<!-- cross-ref:start -->

## See also (related skills — Pi family)

If your issue relates to:
- **using Pi: workspace, sessions, /commands, providers, themes, keybindings** — check `pi-using` if appropriate.

<!-- cross-ref:end -->

