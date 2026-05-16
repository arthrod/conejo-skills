# State Management Patterns

## State Flow Architecture

```
┌──────────────┐    StateSnapshotEvent    ┌──────────────┐
│   Backend    │ ─────────────────────────► │   Frontend   │
│  Agent State │                            │  useCoAgent  │
│              │    StateDeltaEvent         │    state     │
│              │ ─────────────────────────► │              │
│              │                            │              │
│              │ ◄───────────────────────── │              │
│              │    setState() changes      │              │
└──────────────┘                            └──────────────┘
```

## Pattern 1: Full State Replacement

Use when state is small or needs complete refresh.

**Backend:**
```python
@agent.tool_plain
async def get_full_state() -> StateSnapshotEvent:
    return StateSnapshotEvent(
        type=EventType.STATE_SNAPSHOT,
        snapshot={
            "users": fetch_all_users(),
            "settings": get_settings(),
            "timestamp": datetime.now().isoformat()
        }
    )
```

**Frontend:**
```tsx
const { state } = useCoAgent({
  name: "myAgent",
  initialState: { users: [], settings: {}, timestamp: null }
});
// State automatically updates when backend sends snapshot
```

## Pattern 2: Incremental Updates (JSON Patch)

Use for large state with small changes. More efficient than full replacement.

**Backend:**
```python
class JSONPatchOp(BaseModel):
    op: Literal['add', 'remove', 'replace']
    path: str
    value: Any = None

@agent.tool_plain
async def add_user(name: str) -> StateDeltaEvent:
    return StateDeltaEvent(
        type=EventType.STATE_DELTA,
        delta=[
            JSONPatchOp(op='add', path='/users/-', value={"name": name}),
            JSONPatchOp(op='replace', path='/userCount', value=get_count() + 1)
        ]
    )

@agent.tool_plain
async def update_user(index: int, name: str) -> StateDeltaEvent:
    return StateDeltaEvent(
        type=EventType.STATE_DELTA,
        delta=[
            JSONPatchOp(op='replace', path=f'/users/{index}/name', value=name)
        ]
    )

@agent.tool_plain
async def remove_user(index: int) -> StateDeltaEvent:
    return StateDeltaEvent(
        type=EventType.STATE_DELTA,
        delta=[
            JSONPatchOp(op='remove', path=f'/users/{index}')
        ]
    )
```

## Pattern 3: Optimistic UI with Rollback

Update UI immediately, sync with backend, rollback on error.

**Frontend:**
```tsx
const { state, setState } = useCoAgent<AppState>({
  name: "myAgent",
  initialState: { items: [], pending: [] }
});

const addItemOptimistic = async (item: Item) => {
  // 1. Save rollback state
  const rollback = { ...state };
  
  // 2. Optimistic update
  setState(prev => ({
    ...prev,
    items: [...prev.items, item],
    pending: [...prev.pending, item.id]
  }));
  
  // 3. Backend will confirm or we rollback
  // (Agent response will update state if successful)
};
```

## Pattern 4: Predictive State Streaming

Stream partial state as agent processes.

**Backend:**
```python
@agent.tool_plain
async def enable_streaming() -> CustomEvent:
    return CustomEvent(
        type=EventType.CUSTOM,
        name='PredictState',
        value=[{
            'state_key': 'content',      # Which state field
            'tool': 'generate_content',   # Which tool produces it
            'tool_argument': 'text',      # Which argument contains it
        }]
    )

@agent.tool_plain
async def generate_content(text: str) -> StateSnapshotEvent:
    # This streams as agent generates 'text' argument
    return StateSnapshotEvent(
        type=EventType.STATE_SNAPSHOT,
        snapshot={"content": text, "complete": True}
    )
```

**Frontend:**
```tsx
const { state } = useCoAgent({
  name: "myAgent",
  initialState: { content: "", complete: false }
});

// UI updates in real-time as agent generates
<div>
  <p>{state.content}</p>
  {!state.complete && <LoadingIndicator />}
</div>
```

## Pattern 5: Multi-Step Workflow State

Track progress through sequential operations.

**Backend:**
```python
class WorkflowState(BaseModel):
    current_step: int = 0
    total_steps: int = 0
    steps: list[dict] = Field(default_factory=list)
    results: dict = Field(default_factory=dict)

@agent.tool_plain
async def start_workflow(steps: list[str]) -> StateSnapshotEvent:
    return StateSnapshotEvent(
        type=EventType.STATE_SNAPSHOT,
        snapshot={
            "current_step": 0,
            "total_steps": len(steps),
            "steps": [{"name": s, "status": "pending"} for s in steps],
            "results": {}
        }
    )

@agent.tool_plain
async def complete_step(index: int, result: Any) -> StateDeltaEvent:
    return StateDeltaEvent(
        type=EventType.STATE_DELTA,
        delta=[
            JSONPatchOp(op='replace', path=f'/steps/{index}/status', value='complete'),
            JSONPatchOp(op='replace', path='/current_step', value=index + 1),
            JSONPatchOp(op='add', path=f'/results/step_{index}', value=result)
        ]
    )
```

**Frontend:**
```tsx
const { state } = useCoAgent<WorkflowState>({
  name: "workflowAgent",
  initialState: { current_step: 0, total_steps: 0, steps: [], results: {} }
});

<ProgressTracker
  current={state.current_step}
  total={state.total_steps}
  steps={state.steps}
/>
```

## Pattern 6: Bidirectional Sync

Frontend changes trigger backend processing.

**Frontend:**
```tsx
const { state, setState } = useCoAgent({
  name: "myAgent",
  initialState: { query: "", results: [] }
});

// User input triggers state change
const handleSearch = (query: string) => {
  setState(prev => ({ ...prev, query }));
  // Backend agent sees updated state and can respond
};
```

**Backend (using dynamic instructions):**
```python
@agent.instructions
async def react_to_state(ctx: RunContext[StateDeps[AppState]]) -> str:
    state = ctx.deps.state
    if state.query:
        return f"User is searching for: {state.query}. Provide relevant results."
    return "Waiting for user input."
```

## State Type Definitions

Keep types in sync between frontend and backend:

**Backend (Python):**
```python
class PortfolioState(BaseModel):
    holdings: dict[str, float] = Field(default_factory=dict)
    cash: float = 100000.0
    performance_data: list[dict] = Field(default_factory=list)
    
    class Config:
        json_schema_extra = {
            "example": {
                "holdings": {"AAPL": 100, "MSFT": 50},
                "cash": 50000.0,
                "performance_data": [
                    {"date": "2024-01", "value": 100000}
                ]
            }
        }
```

**Frontend (TypeScript):**
```tsx
interface PortfolioState {
  holdings: Record<string, number>;
  cash: number;
  performance_data: Array<{
    date: string;
    value: number;
  }>;
}

const { state } = useCoAgent<PortfolioState>({
  name: "portfolioAgent",
  initialState: {
    holdings: {},
    cash: 100000,
    performance_data: []
  }
});
```
