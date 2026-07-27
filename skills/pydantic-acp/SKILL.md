---
name: pydantic-acp
description: Use pydantic-acp to drive an external ACP CLI agent (crush-acp, cline --acp) as a pydantic-ai model backend — create_acp_model, AcpProvider, delegate host clients (filesystem/terminal/permissions), PromptedOutput structured output, and the classic hang/leak gotchas. Use when wrapping cline/crush/any ACP agent in a pydantic_ai.Agent, when acp logs "Error parsing JSON-RPC message" / "Expecting value: line 1 column 1", when an ACP-backed run hangs until its timeout, or when implementing an acp.interfaces.Client delegate.
---

# pydantic-acp: ACP agents as pydantic-ai models

`pydantic-acp` (>=1.4.0) is the inverse of the usual ACP server adapter: it wraps an
existing **ACP agent** (a CLI like crush or cline speaking Agent Client Protocol over
stdio) as a **pydantic-ai provider/model pair**. Pydantic AI still owns the outer agent
run, output validation, usage, and history; the ACP agent does the actual model turn
and tool execution on its side.

```
pydantic_ai.Agent
  └─ AcpModel                      (Model; profile: supports_tools=False)
      └─ AcpProvider               (owns initialize/new_session/prompt lifecycle)
          ├─ AcpCommandAgent       (spawns the ACP CLI subprocess — LAZILY)
          └─ AcpHostBridge         (receives session_update; forwards host ops
              └─ your delegate      to your acp.interfaces.Client implementation)
```

## Quick start

```python
from pydantic_acp import create_acp_model
from pydantic_ai import Agent
from pydantic_ai.output import PromptedOutput

model = create_acp_model(
    acp_command=["crush-acp"],        # must be a real ACP stdio server!
    cwd=str(repo_path),
    delegate_client=my_delegate,      # acp.interfaces.Client impl (see below)
    history_mode="full",              # or "latest_user" (default)
)
agent = Agent(model, output_type=PromptedOutput(MyResult), instructions=...)
result = await agent.run(prompt)      # result.output is a validated MyResult
```

## Critical gotchas (each one cost a real debugging session)

1. **The command must be an ACP stdio server, not the bare CLI.**
   - crush: the ACP bridge is the separate binary `crush-acp`. Bare `crush` opens the TUI.
   - cline: needs the flag — `["cline", "--acp"]`. Bare `cline` starts interactive
     act-mode with auto-approve and prints styled text to stdout.
   - Symptom of getting this wrong: `ERROR:root:Error parsing JSON-RPC message` /
     `json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)` from
     `acp/connection.py`'s `_receive_loop`, and the `initialize` request never resolves,
     so `agent.run` hangs for the FULL timeout. Sometimes there are no JSON errors at
     all — just a silent hang.

2. **`create_acp_model` spawns lazily.** The subprocess is created on the *first ACP
   call* (inside `agent.run`), not at construction. A try/except around the factory can
   never catch a bad/missing binary — preflight with `shutil.which(cmd[0])` and, for a
   real health check, probe the handshake: write one `initialize` JSON-RPC line to the
   process's stdin and `asyncio.wait_for(stdout.readline(), 15)`.

3. **Timeout cancellation leaks the subprocess.** `asyncio.wait_for(agent.run(...), t)`
   cancels the coroutine but the spawned ACP CLI keeps running (possibly with
   auto-approve!). Always close in a `finally`:

   ```python
   finally:
       with suppress(Exception):
           provider = getattr(model, "_provider", None)  # AcpProvider
           if provider is not None:
               await provider.close()   # closes AcpCommandAgent → terminates process
   ```

4. **cline's ACP prompt stage is broken** (verified through cline 3.0.46, 2026-07):
   `cline --acp` completes the `initialize` handshake fine but stores prompts without
   ever running them → hangs at the prompt stage. Prefer `crush-acp`.

5. **No pydantic-ai function tools.** `AcpModel`'s profile is `supports_tools=False`;
   registering function tools or native tools on the `Agent` raises `UserError` at
   request time. Tools belong on the ACP agent's side, reached through the host bridge.

6. **Structured output must be `PromptedOutput`.** The default `ToolOutput` mechanism
   needs `output_tools`, which `AcpModel` rejects unless the remote agent implements
   pydantic-acp's private `_meta` protocol (only agents built with this same package
   do). `PromptedOutput(MyModel)` works: text turn + validated parse. Type checkers see
   the wrapper type, but runtime `result.output` is the pydantic model — `cast` it.

7. **Model selection needs remote support.** `provider.model("some-model")` sends
   `session/set_config_option("model", ...)`; if the ACP agent doesn't expose a
   selectable `model` config option this raises `UserError`. Pass `model_name=None`
   (the default) to keep the agent's own default; the visible model name is `"agent"`.

## The delegate client (real filesystem / terminal / permissions)

`AcpHostBridge` records `session_update`s (that's how agent text gets back into the
`ModelResponse`) and forwards every other host operation to your delegate. **With no
delegate, any host op raises `RuntimeError`** — an agent that tries to read a file will
crash the run. Implement `acp.interfaces.Client`:

- `request_permission(...)` → `RequestPermissionResponse(outcome=AllowedOutcome(option_id=..., outcome="selected"))`.
  Both `option_id` AND `outcome="selected"` are required. This method is also your one
  HARD control point: auto-allow for worker sessions, deny for judge/read-only sessions
  (session modes are advisory; permission responses are not).
- `read_text_file(...)` → `ReadTextFileResponse(content=str)`. `content` is the ONLY
  field — no `path`, no `error`; encode failures INTO the content string.
- `write_text_file(...)` → return `None` (the response type has no fields).
- `create_terminal(...)` → `CreateTerminalResponse(terminal_id=...)`; you own the
  subprocess, its output draining, and exit tracking.
- `terminal_output(...)` → `TerminalOutputResponse(output=str, truncated=bool)` —
  `truncated` is required; errors go INTO `output`.
- `wait_for_terminal_exit(...)` → `WaitForTerminalExitResponse(exit_code=int|None)` —
  use `None` for unknown/missing terminals, never a -1 sentinel (exit_code must be ≥ 0).
- Also stub: `session_update`, `release_terminal`, `kill_terminal`,
  `create_elicitation` (raise in autonomous mode), `complete_elicitation`,
  `ext_method` (return `{}`), `ext_notification`, `on_connect`.

Field naming: the acp Python SDK models use **snake_case** field names (`option_id`,
`terminal_id`) with camelCase wire aliases and `populate_by_name=True` — both spellings
are accepted; write snake_case in Python.

## Session modes and the judge-must-not-act pattern

pydantic-acp 1.4.0 has no public session-priming hook. To set a mode (yolo/ask) you
must reach in: `await provider._ensure_session(model_name=None)` then
`await provider.client.set_session_mode(mode_id=..., session_id=provider.session_id)` —
best-effort only. The guarantee that a judge/decider session cannot act must live in
the delegate's `request_permission` (deny everything), not in the mode.

## history_mode

- `"latest_user"` (default): each turn sends only the newest user message — fine for
  one-shot runs, loses context in multi-turn pydantic-ai loops (e.g. retries).
- `"full"`: renders the whole conversation (instructions, tool returns, retry prompts)
  as one text block per turn. Use this for agents with `retries=` or output validators.

## Symptom → cause cheat sheet

| Symptom | Cause |
|---|---|
| `JSONDecodeError: Expecting value` from `acp/connection.py` | Spawned command isn't an ACP server (bare `cline`/`crush`) |
| `agent.run` hangs exactly until your timeout, no errors | `initialize` unanswered (wrong command), or cline's broken prompt stage |
| Provider fallback logic never triggers | Lazy spawn — nothing fails at `create_acp_model` time |
| Orphan cline/crush processes after timeouts | Missing `provider.close()` in a `finally` |
| `UserError: cannot execute Pydantic AI function tools` | Tools registered on the pydantic-ai `Agent` — move them to the ACP side |
| `UserError: text-response provider bridge` on structured output | Using default `ToolOutput` — switch to `PromptedOutput` |
| `RuntimeError: ACP agent requested host method ...` | No `delegate_client` supplied |
| `UserError: does not expose a selectable 'model' option` | Passed `model_name` to an agent without a `model` config option |
