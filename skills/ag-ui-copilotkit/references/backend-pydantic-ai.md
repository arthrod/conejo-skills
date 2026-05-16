# Backend: Pydantic AI with AG-UI

## Agent Setup

```python
from pydantic_ai import Agent, RunContext
from pydantic_ai.ag_ui import StateDeps
from ag_ui.core import EventType, StateSnapshotEvent, StateDeltaEvent, CustomEvent
from pydantic import BaseModel, Field
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# 1. Define state model
class AppState(BaseModel):
    data: dict = Field(default_factory=dict)
    status: str = "idle"

# 2. Create agent with state dependency
agent = Agent(
    'openai:gpt-4o-mini',
    deps_type=StateDeps[AppState]
)

# 3. Convert to FastAPI app
app = agent.to_ag_ui(deps=StateDeps(AppState()))

# 4. Add CORS for frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## Tool Patterns

### Basic Tool (No State)

```python
@agent.tool_plain
async def simple_tool(query: str) -> str:
    """Tool that returns plain text."""
    return f"Result: {query}"
```

### Tool with State Snapshot

Send complete state replacement to frontend:

```python
@agent.tool_plain
async def update_all(items: list[str]) -> StateSnapshotEvent:
    """Replace entire state."""
    return StateSnapshotEvent(
        type=EventType.STATE_SNAPSHOT,
        snapshot={"items": items, "count": len(items)}
    )
```

### Tool with State Delta (JSON Patch)

Send incremental updates (RFC 6902):

```python
from typing import Literal, Any

class JSONPatchOp(BaseModel):
    op: Literal['add', 'remove', 'replace', 'move', 'copy', 'test']
    path: str
    value: Any = None

@agent.tool_plain
async def update_item(index: int, value: str) -> StateDeltaEvent:
    """Update single item via JSON Patch."""
    return StateDeltaEvent(
        type=EventType.STATE_DELTA,
        delta=[
            JSONPatchOp(op='replace', path=f'/items/{index}', value=value)
        ]
    )
```

### Tool with Context Access

Access current state in tool:

```python
@agent.tool
async def context_aware_tool(ctx: RunContext[StateDeps[AppState]], query: str) -> str:
    """Tool that reads current state."""
    current = ctx.deps.state
    return f"Current status: {current.status}, query: {query}"
```

## Dynamic Instructions

Provide context-aware instructions based on state:

```python
@agent.instructions
async def dynamic_instructions(ctx: RunContext[StateDeps[AppState]]) -> str:
    state = ctx.deps.state
    return f"""
    Current application state:
    - Status: {state.status}
    - Data: {state.data}
    
    Respond based on this context.
    """
```

## Predictive State Updates

Enable streaming state predictions:

```python
@agent.tool_plain
async def enable_prediction() -> list[CustomEvent]:
    """Enable predictive state for a field."""
    return [
        CustomEvent(
            type=EventType.CUSTOM,
            name='PredictState',
            value=[{
                'state_key': 'document',
                'tool': 'write_document',
                'tool_argument': 'content',
            }]
        )
    ]
```

## Multiple Event Returns

Tools can return multiple events:

```python
@agent.tool_plain
async def multi_event_tool() -> list[StateSnapshotEvent | CustomEvent]:
    return [
        StateSnapshotEvent(type=EventType.STATE_SNAPSHOT, snapshot={"step": 1}),
        CustomEvent(type=EventType.CUSTOM, name="StepComplete", value={"step": 1}),
    ]
```

## FastAPI Integration

### Mount Multiple Agents

```python
from fastapi import FastAPI

main_app = FastAPI()

# Create separate agents
chat_agent = Agent('openai:gpt-4o-mini')
analysis_agent = Agent('openai:gpt-4o')

# Mount as sub-applications
main_app.mount('/chat', chat_agent.to_ag_ui())
main_app.mount('/analysis', analysis_agent.to_ag_ui())
```

### With CopilotKit Runtime Proxy

Create `/api/copilotkit/route.ts` in Next.js:

```typescript
import { CopilotRuntime, ExperimentalEmptyStateGuardrail } from "@copilotkit/runtime";
import { NextRequest } from "next/server";

export async function POST(req: NextRequest) {
  const runtime = new CopilotRuntime({
    remoteEndpoints: [
      {
        url: process.env.BACKEND_URL || "http://localhost:8000",
      },
    ],
  });
  
  return runtime.streamHttpServerResponse(req, new Response());
}
```

## Error Handling

```python
from fastapi import HTTPException

@agent.tool_plain
async def validated_tool(amount: float) -> StateSnapshotEvent:
    if amount < 0:
        raise HTTPException(status_code=400, detail="Amount must be positive")
    return StateSnapshotEvent(
        type=EventType.STATE_SNAPSHOT,
        snapshot={"amount": amount}
    )
```

## Complete Example: Stock Portfolio Agent

```python
from pydantic_ai import Agent, RunContext
from pydantic_ai.ag_ui import StateDeps
from ag_ui.core import EventType, StateSnapshotEvent
from pydantic import BaseModel, Field
import yfinance as yf

class PortfolioState(BaseModel):
    holdings: dict[str, float] = Field(default_factory=dict)
    cash: float = 100000.0
    performance: list[dict] = Field(default_factory=list)

agent = Agent(
    'openai:gpt-4o-mini',
    deps_type=StateDeps[PortfolioState],
    instructions="""You are a portfolio analysis agent. Use tools to:
    - Fetch stock data
    - Calculate returns
    - Update portfolio state
    Always use display_portfolio to show results."""
)

@agent.tool_plain
async def fetch_stock(ticker: str, start_date: str) -> dict:
    """Fetch historical stock data."""
    stock = yf.Ticker(ticker)
    hist = stock.history(start=start_date)
    return {
        "ticker": ticker,
        "prices": hist['Close'].to_dict(),
        "current_price": hist['Close'].iloc[-1]
    }

@agent.tool_plain
async def display_portfolio(
    holdings: dict[str, float],
    cash: float,
    performance: list[dict]
) -> StateSnapshotEvent:
    """Display portfolio to user."""
    return StateSnapshotEvent(
        type=EventType.STATE_SNAPSHOT,
        snapshot={
            "holdings": holdings,
            "cash": cash,
            "performance": performance
        }
    )

app = agent.to_ag_ui(deps=StateDeps(PortfolioState()))
```
