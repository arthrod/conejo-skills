---
name: ag-ui-pydantic
description: Build AI agent UIs using the AG-UI protocol with pydantic-ai (Python backend) and CopilotKit (React frontend). Use when creating agentic chat interfaces, human-in-the-loop workflows, generative UIs with state management, tool-based rendering, shared state between frontend and backend, or predictive state updates. Covers FastAPI integration, state events (StateSnapshotEvent, StateDeltaEvent, CustomEvent), useCoAgent hooks, useCopilotAction for tool rendering, and real-time agent-frontend synchronization.
---

# AG-UI with Pydantic AI

Build agentic UIs where Python agents communicate with React frontends via the AG-UI protocol.

## Architecture Overview

```
┌─────────────────┐     AG-UI Protocol      ┌──────────────────┐
│  Pydantic AI    │ ◄──────────────────────►│   CopilotKit     │
│  (FastAPI)      │   Events & State        │   (React/Next)   │
└─────────────────┘                         └──────────────────┘
```

## Quick Start

**Backend (Python):**
```python
from pydantic_ai import Agent

agent = Agent('openai:gpt-4o-mini')
app = agent.to_ag_ui()  # Creates FastAPI-compatible ASGI app
```

**Frontend (React):**
```tsx
<CopilotKit runtimeUrl="/api/copilotkit" agent="myAgent">
  <CopilotChat />
</CopilotKit>
```

## Core Patterns

### 1. Agentic Chat (Basic)
Simple chat with server-side tools. See `references/backend-patterns.md#agentic-chat`.

### 2. Shared State
Bidirectional state sync between agent and UI using `StateDeps`:
```python
from pydantic_ai.ag_ui import StateDeps

agent = Agent('openai:gpt-4o-mini', deps_type=StateDeps[MyStateModel])
app = agent.to_ag_ui(deps=StateDeps(MyStateModel()))
```
See `references/backend-patterns.md#shared-state`.

### 3. Generative UI
Agent emits state events that frontend renders:
- `StateSnapshotEvent` - Replace entire state
- `StateDeltaEvent` - JSON Patch operations
- `CustomEvent` - Custom frontend triggers

See `references/backend-patterns.md#generative-ui`.

### 4. Human in the Loop
Tools that wait for user confirmation via `renderAndWaitForResponse`.
See `references/frontend-patterns.md#human-in-the-loop`.

### 5. Predictive State Updates
Stream partial state before tool completion.
See `references/backend-patterns.md#predictive-state`.

## Key Integration Points

### Backend → Frontend Events
Tools return AG-UI events directly:
```python
@agent.tool_plain
async def update_ui(data: str) -> StateSnapshotEvent:
    return StateSnapshotEvent(
        type=EventType.STATE_SNAPSHOT,
        snapshot={"field": data}
    )
```

### Frontend → Backend State
Use `useCoAgent` for bidirectional state:
```tsx
const { state, setState } = useCoAgent({
  name: "myAgent",
  initialState: { /* ... */ }
});
```

## Resources

- **Backend patterns**: `references/backend-patterns.md` - Python/pydantic-ai implementation details
- **Frontend patterns**: `references/frontend-patterns.md` - React/CopilotKit implementation details

<!-- cross-ref:start -->

## See also (related skills — AG-UI family)

If your issue relates to:
- **AG-UI protocol with CopilotKit** — check `ag-ui-copilotkit` if appropriate.

<!-- cross-ref:end -->

