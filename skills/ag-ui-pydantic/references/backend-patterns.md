# AG-UI Backend Patterns (Python/Pydantic AI)

## Setup

```python
from pydantic_ai import Agent
from fastapi import FastAPI
import uvicorn

agent = Agent('openai:gpt-4o-mini')
app = agent.to_ag_ui()

# Or mount on existing FastAPI app:
main_app = FastAPI()
main_app.mount('/agent', agent.to_ag_ui())
```

## Agentic Chat

Basic agent with tools:

```python
from datetime import datetime
from zoneinfo import ZoneInfo
from pydantic_ai import Agent

agent = Agent('openai:gpt-4o-mini')
app = agent.to_ag_ui()

@agent.tool_plain
async def current_time(timezone: str = 'UTC') -> str:
    """Get current time in ISO format."""
    tz = ZoneInfo(timezone)
    return datetime.now(tz=tz).isoformat()
```

## Shared State

Bidirectional state between agent and frontend:

```python
from pydantic import BaseModel, Field
from pydantic_ai import Agent, RunContext
from pydantic_ai.ag_ui import StateDeps
from ag_ui.core import EventType, StateSnapshotEvent

class RecipeState(BaseModel):
    ingredients: list[str] = Field(default_factory=list)
    instructions: list[str] = Field(default_factory=list)

agent = Agent('openai:gpt-4o-mini', deps_type=StateDeps[RecipeState])

@agent.tool_plain
async def display_recipe(recipe: RecipeState) -> StateSnapshotEvent:
    """Send recipe state to frontend."""
    return StateSnapshotEvent(
        type=EventType.STATE_SNAPSHOT,
        snapshot={'recipe': recipe.model_dump()}
    )

@agent.instructions
async def dynamic_instructions(ctx: RunContext[StateDeps[RecipeState]]) -> str:
    """Access current state in instructions."""
    return f"Current ingredients: {ctx.deps.state.ingredients}"

# Initialize with state
app = agent.to_ag_ui(deps=StateDeps(RecipeState()))
```

## Generative UI

### State Snapshot (Replace All)

```python
from ag_ui.core import EventType, StateSnapshotEvent

@agent.tool_plain
async def create_plan(steps: list[str]) -> StateSnapshotEvent:
    return StateSnapshotEvent(
        type=EventType.STATE_SNAPSHOT,
        snapshot={
            'steps': [{'description': s, 'status': 'pending'} for s in steps]
        }
    )
```

### State Delta (JSON Patch)

```python
from typing import Any, Literal
from pydantic import BaseModel, Field
from ag_ui.core import EventType, StateDeltaEvent

class JSONPatchOp(BaseModel):
    op: Literal['add', 'remove', 'replace', 'move', 'copy', 'test']
    path: str
    value: Any = None
    from_: str | None = Field(default=None, alias='from')

@agent.tool_plain
async def update_step(index: int, status: str) -> StateDeltaEvent:
    return StateDeltaEvent(
        type=EventType.STATE_DELTA,
        delta=[JSONPatchOp(op='replace', path=f'/steps/{index}/status', value=status)]
    )
```

### Custom Events

```python
from ag_ui.core import CustomEvent, EventType

@agent.tool_plain
async def trigger_animation() -> CustomEvent:
    return CustomEvent(
        type=EventType.CUSTOM,
        name='PlayAnimation',
        value={'animation': 'confetti', 'duration': 3000}
    )
```

## Predictive State

Enable frontend to predict state from tool arguments before completion:

```python
from ag_ui.core import CustomEvent, EventType

@agent.tool_plain
async def enable_document_prediction() -> list[CustomEvent]:
    return [
        CustomEvent(
            type=EventType.CUSTOM,
            name='PredictState',
            value=[{
                'state_key': 'document',
                'tool': 'write_document',
                'tool_argument': 'content'
            }]
        )
    ]
```

## Instructions Patterns

### Static Instructions

```python
agent = Agent(
    'openai:gpt-4o-mini',
    instructions="You are a helpful assistant."
)
```

### Dynamic Instructions (State-Aware)

```python
from textwrap import dedent

@agent.instructions
async def instructions(ctx: RunContext[StateDeps[MyState]]) -> str:
    return dedent(f"""
        You are a helpful assistant.
        Current state: {ctx.deps.state.model_dump_json(indent=2)}
        
        Rules:
        - Use display_result tool to show results
        - Do NOT repeat results in messages
    """)
```

## Common Anti-Patterns

**DON'T** repeat tool output in messages:
```python
# Bad - agent instructions allow repeating
instructions = "Show results to user"

# Good - explicit instruction to use tools only
instructions = """
Use the display_result tool to show results.
Do NOT repeat results as text messages.
"""
```

**DON'T** call state-changing tools multiple times:
```python
# Add to instructions:
instructions = """
Do NOT call display_result multiple times in a row.
"""
```
