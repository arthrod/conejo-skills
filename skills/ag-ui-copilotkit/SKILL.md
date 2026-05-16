---
name: ag-ui-copilotkit
description: Build agentic UIs using AG-UI protocol with Pydantic AI (Python backend) and CopilotKit (React/Next.js frontend). Use when creating AI-powered applications that need bidirectional agent-UI communication, shared state between frontend and backend, human-in-the-loop workflows, tool-based generative UI, or predictive state updates. Triggers on requests involving CopilotKit hooks (useCoAgent, useCopilotAction, useCoAgentStateRender), pydantic_ai with ag_ui adapters, or building chat interfaces with backend AI agents.
---

# AG-UI + CopilotKit Development

Build agentic UIs with bidirectional communication between AI agents and React frontends.

## Architecture Overview

```
┌─────────────────────┐     AG-UI Protocol      ┌─────────────────────┐
│   Next.js Frontend  │ ◄──────────────────────►│  FastAPI Backend    │
│   (CopilotKit)      │   SSE Event Stream      │  (Pydantic AI)      │
│                     │                          │                     │
│ • useCoAgent        │   Events:               │ • Agent + tools     │
│ • useCopilotAction  │   - TextMessageStart    │ • to_ag_ui()        │
│ • useCopilotReadable│   - ToolCallStart       │ • StateDeps         │
│ • useCoAgentState   │   - StateSnapshot       │ • StateSnapshot     │
│   Render            │   - StateDelta          │ • StateDelta        │
└─────────────────────┘                          └─────────────────────┘
```

## Quick Start

### Backend (Python with Pydantic AI)

```python
from pydantic_ai import Agent
from ag_ui.core import EventType, StateSnapshotEvent

agent = Agent('openai:gpt-4o-mini')
app = agent.to_ag_ui()  # Creates FastAPI app

@agent.tool_plain
async def my_tool(param: str) -> StateSnapshotEvent:
    return StateSnapshotEvent(
        type=EventType.STATE_SNAPSHOT,
        snapshot={"result": param}
    )
```

### Frontend (React with CopilotKit)

```tsx
// layout.tsx - Wrap app with CopilotKit
<CopilotKit runtimeUrl="/api/copilotkit" agent="myAgent">
  {children}
</CopilotKit>

// page.tsx - Use hooks
const { state, setState } = useCoAgent({
  name: "myAgent",
  initialState: { /* ... */ }
});

useCopilotAction({
  name: "my_action",
  parameters: [{ name: "param", type: "string" }],
  renderAndWaitForResponse: ({ args, respond, status }) => (
    <MyComponent onAccept={() => respond("accepted")} />
  )
});
```

## Core Patterns

### 1. Shared State

Backend sends state updates; frontend renders and can modify.

**Backend:** Return `StateSnapshotEvent` or `StateDeltaEvent` from tools  
**Frontend:** Use `useCoAgent` to receive and manage state

### 2. Human-in-the-Loop

Agent proposes actions; user approves/rejects via UI.

**Backend:** Define tools that the frontend will render  
**Frontend:** Use `useCopilotAction` with `renderAndWaitForResponse`

### 3. Tool-Based Generative UI

Agent calls tools; frontend renders custom components for tool output.

**Backend:** Tools return structured data  
**Frontend:** `useCopilotAction` renders components based on tool parameters

### 4. Predictive State Updates

Stream partial state while agent is processing.

**Backend:** Return `CustomEvent` with `PredictState` configuration  
**Frontend:** UI updates optimistically as agent generates

## Detailed References

- **Backend patterns**: See [references/backend-pydantic-ai.md](references/backend-pydantic-ai.md)
- **Frontend patterns**: See [references/frontend-copilotkit.md](references/frontend-copilotkit.md)
- **State management**: See [references/state-patterns.md](references/state-patterns.md)

## Common Pitfalls

1. **Missing CORS**: Backend must allow frontend origin
2. **State sync**: Always use `useCoAgent` name matching backend agent name
3. **Tool names**: Must match between `useCopilotAction` and backend tools
4. **SSE handling**: CopilotKit runtime must proxy to backend correctly

<!-- cross-ref:start -->

## See also (related skills — AG-UI family)

If your issue relates to:
- **AG-UI protocol with Pydantic AI (Python backend)** — check `ag-ui-pydantic` if appropriate.

<!-- cross-ref:end -->

