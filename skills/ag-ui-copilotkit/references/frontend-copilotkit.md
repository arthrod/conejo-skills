# Frontend: CopilotKit with React/Next.js

## Setup

### Install Dependencies

```bash
bun add @copilotkit/react-core @copilotkit/react-ui @copilotkit/runtime
```

### Layout Configuration

```tsx
// app/layout.tsx
import { CopilotKit } from "@copilotkit/react-core";
import "@copilotkit/react-ui/styles.css";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html>
      <body>
        <CopilotKit 
          runtimeUrl="/api/copilotkit" 
          agent="myAgent"  // Must match backend agent name
        >
          {children}
        </CopilotKit>
      </body>
    </html>
  );
}
```

### API Route (App Router)

```tsx
// app/api/copilotkit/route.ts
import { CopilotRuntime } from "@copilotkit/runtime";
import { NextRequest } from "next/server";

export async function POST(req: NextRequest) {
  const runtime = new CopilotRuntime({
    remoteEndpoints: [{
      url: process.env.BACKEND_URL || "http://localhost:8000",
    }],
  });
  return runtime.streamHttpServerResponse(req, new Response());
}
```

## Core Hooks

### useCoAgent - Shared State

Bidirectional state sync with backend agent:

```tsx
"use client";
import { useCoAgent } from "@copilotkit/react-core";

interface AgentState {
  items: string[];
  count: number;
  status: "idle" | "processing" | "complete";
}

export function MyComponent() {
  const { state, setState } = useCoAgent<AgentState>({
    name: "myAgent",  // Must match CopilotKit agent prop
    initialState: {
      items: [],
      count: 0,
      status: "idle"
    }
  });

  // State updates from backend automatically reflect here
  // Local setState changes sync back to agent context
  
  return (
    <div>
      <p>Status: {state.status}</p>
      <p>Count: {state.count}</p>
      <ul>
        {state.items.map((item, i) => <li key={i}>{item}</li>)}
      </ul>
      <button onClick={() => setState(prev => ({
        ...prev,
        items: [...prev.items, "new item"]
      }))}>
        Add Item
      </button>
    </div>
  );
}
```

### useCoAgentStateRender - Custom State Rendering

Render UI based on agent state changes:

```tsx
import { useCoAgentStateRender } from "@copilotkit/react-core";

useCoAgentStateRender({
  name: "myAgent",
  render: ({ state }) => {
    if (state?.loading) {
      return <LoadingSpinner />;
    }
    if (state?.error) {
      return <ErrorDisplay error={state.error} />;
    }
    return null;  // Don't render if no special state
  }
});
```

### useCopilotAction - Human-in-the-Loop

Define frontend actions the agent can trigger:

```tsx
import { useCopilotAction } from "@copilotkit/react-core";

useCopilotAction({
  name: "display_chart",  // Must match backend tool name
  description: "Display a chart with data",
  parameters: [
    {
      name: "data",
      type: "object[]",
      attributes: [
        { name: "label", type: "string", required: true },
        { name: "value", type: "number", required: true }
      ]
    },
    {
      name: "title",
      type: "string",
      required: true
    }
  ],
  renderAndWaitForResponse: ({ args, respond, status }) => {
    // Render UI for user interaction
    return (
      <div>
        <h3>{args.title}</h3>
        <MyChart data={args.data} />
        
        {status !== "complete" && (
          <>
            <button onClick={() => respond("Chart accepted")}>
              Accept
            </button>
            <button onClick={() => respond("Chart rejected")}>
              Reject
            </button>
          </>
        )}
      </div>
    );
  }
});
```

### useCopilotReadable - Context for Agent

Provide data the agent can read:

```tsx
import { useCopilotReadable } from "@copilotkit/react-core";

const [userData, setUserData] = useState({ name: "John", preferences: {} });

useCopilotReadable({
  description: "Current user profile and preferences",
  value: JSON.stringify(userData)
});
```

### useCopilotChatSuggestions - Chat Prompts

Provide contextual suggestions:

```tsx
import { useCopilotChatSuggestions } from "@copilotkit/react-ui";

useCopilotChatSuggestions({
  available: selectedItem ? "enabled" : "disabled",
  instructions: "Suggest actions for the selected item"
}, [selectedItem]);
```

## CopilotChat Component

Built-in chat interface:

```tsx
import { CopilotChat } from "@copilotkit/react-ui";

<CopilotChat 
  className="h-[500px]"
  labels={{
    initial: "How can I help you today?",
    placeholder: "Type a message..."
  }}
/>
```

## Complex Action Parameters

For nested/complex data structures:

```tsx
useCopilotAction({
  name: "render_portfolio",
  parameters: [
    {
      name: "investment_summary",
      type: "object",
      attributes: [
        {
          name: "holdings",
          type: "object",
          description: "Stock holdings {ticker: shares}",
          attributes: [],
          required: true
        },
        {
          name: "performanceData",
          type: "object[]",
          attributes: [
            { name: "date", type: "string", required: true },
            { name: "portfolio", type: "number", required: true },
            { name: "benchmark", type: "number", required: true }
          ]
        },
        {
          name: "total_value",
          type: "number",
          required: true
        }
      ]
    },
    {
      name: "insights",
      type: "object",
      attributes: [
        {
          name: "bullish",
          type: "object[]",
          attributes: [
            { name: "title", type: "string", required: true },
            { name: "description", type: "string", required: true }
          ]
        }
      ]
    }
  ],
  renderAndWaitForResponse: ({ args, respond, status }) => {
    const { investment_summary, insights } = args;
    // Render complex UI...
  }
});
```

## State Management Pattern

Combine useCoAgent with local state:

```tsx
"use client";
import { useState, useEffect } from "react";
import { useCoAgent, useCoAgentStateRender } from "@copilotkit/react-core";

interface BackendState {
  data: any;
  processing: boolean;
}

interface LocalState {
  selectedItem: string | null;
  viewMode: "grid" | "list";
}

export function Dashboard() {
  // Backend-synced state
  const { state: agentState, setState: setAgentState } = useCoAgent<BackendState>({
    name: "dashboardAgent",
    initialState: { data: null, processing: false }
  });

  // Local-only UI state
  const [localState, setLocalState] = useState<LocalState>({
    selectedItem: null,
    viewMode: "grid"
  });

  // Render loading states from agent
  useCoAgentStateRender({
    name: "dashboardAgent",
    render: ({ state }) => 
      state?.processing ? <LoadingOverlay /> : null
  });

  // Sync specific changes back to agent
  useEffect(() => {
    if (localState.selectedItem) {
      setAgentState(prev => ({
        ...prev,
        selectedItem: localState.selectedItem
      }));
    }
  }, [localState.selectedItem]);

  return (/* ... */);
}
```

## Error Handling

```tsx
useCopilotAction({
  name: "risky_action",
  parameters: [/* ... */],
  renderAndWaitForResponse: ({ args, respond, status }) => {
    const [error, setError] = useState<string | null>(null);
    
    const handleAccept = async () => {
      try {
        // Validate before responding
        if (!args.requiredField) {
          throw new Error("Missing required field");
        }
        respond("Action completed successfully");
      } catch (err) {
        setError(err.message);
        respond(`Error: ${err.message}`);
      }
    };

    return (
      <div>
        {error && <ErrorBanner message={error} />}
        <ActionContent args={args} />
        {status !== "complete" && (
          <button onClick={handleAccept}>Confirm</button>
        )}
      </div>
    );
  }
});
```

## TypeScript Types

```tsx
// Define strict types for agent state
interface PortfolioAgentState {
  available_cash: number;
  investment_portfolio: Array<{
    ticker: string;
    amount: number;
  }>;
  tool_logs: Array<{
    id: string;
    message: string;
    status: "processing" | "completed";
  }>;
}

// Use with useCoAgent
const { state, setState } = useCoAgent<PortfolioAgentState>({
  name: "portfolioAgent",
  initialState: {
    available_cash: 100000,
    investment_portfolio: [],
    tool_logs: []
  }
});
```
