---
name: json-render
description: Use when building Generative UI with json-render — AI generates JSON specs that render as React/Vue/Svelte/Solid/Native/PDF/Email/Video/3D/Terminal/Image components within a fixed catalog. Triggers on @json-render/* imports (core, react, vue, svelte, solid, shadcn, react-native, next, remotion, react-pdf, react-email, ink, react-three-fiber, image, mcp, yaml, codegen, devtools, redux, zustand, jotai, xstate), defineCatalog, defineRegistry, Renderer, $state/$bindState/$cond/$template/$computed expressions, pipeJsonRender, pipeYamlRender, SpecStream, AI streamText to UI generation, or "AI-generated UI" workflows.
---

# json-render

## Overview

**Generative UI framework**: AI emits JSON specs constrained by a catalog you define; a renderer converts each spec into a typed component tree. Same catalog drives web (React/Vue/Svelte/Solid), mobile (React Native), video (Remotion), PDF, email, 3D (R3F), terminal (Ink), and images.

**Core mental model:**

```
Catalog (zod schemas) → Prompt → AI (streamed JSON) → SpecStream patches → Registry (component impls) → Rendered UI
```

You define what the AI is allowed to emit (catalog). The model can only use those component types and actions, with prop schemas enforced. The renderer resolves dynamic `$state` / `$bindState` / `$cond` expressions before passing props down.

## Install Matrix

| Goal | Install |
|---|---|
| React UI | `@json-render/core @json-render/react` |
| React + 36 prebuilt shadcn components | `@json-render/shadcn` |
| Svelte 5 UI | `@json-render/core @json-render/svelte` |
| Svelte + shadcn parity | `@json-render/shadcn-svelte` |
| Vue 3 UI | `@json-render/core @json-render/vue` |
| SolidJS UI | `@json-render/core @json-render/solid` |
| React Native (mobile) | `@json-render/core @json-render/react-native` |
| Full Next.js apps from JSON | `@json-render/core @json-render/react @json-render/next` |
| Remotion video | `@json-render/core @json-render/remotion` |
| PDF documents | `@json-render/core @json-render/react-pdf` |
| HTML email | `@json-render/core @json-render/react-email @react-email/components @react-email/render` |
| Terminal UIs | `@json-render/core @json-render/ink ink react` |
| 3D scenes (incl. Gaussian Splats) | `@json-render/core @json-render/react-three-fiber @react-three/fiber @react-three/drei three` |
| OG images / social cards (SVG/PNG) | `@json-render/core @json-render/image` |
| MCP App for Claude/ChatGPT/Cursor | `@json-render/mcp` |
| YAML wire format | `@json-render/yaml` |
| State store adapters | `@json-render/redux` / `zustand` / `jotai` / `xstate` |
| Devtools | `@json-render/devtools` + `devtools-react/vue/svelte/solid` |
| Codegen from specs | `@json-render/codegen` |

All public packages share one version. **Always `npm view <pkg> version`** before installing.

## Core API (3 Functions)

```typescript
import { defineCatalog } from "@json-render/core";
import { schema } from "@json-render/react/schema";       // pick the renderer's schema
import { defineRegistry, Renderer } from "@json-render/react";
import { z } from "zod";

// 1. CATALOG — what the AI is allowed to emit
const catalog = defineCatalog(schema, {
  components: {
    Card:   { props: z.object({ title: z.string() }), description: "container" },
    Button: { props: z.object({ label: z.string() }), description: "click me" },
  },
  actions: {
    refresh: { params: z.object({}), description: "Refresh data" },
  },
});

// 2. REGISTRY — your actual component implementations
const { registry } = defineRegistry(catalog, {
  components: {
    Card:   ({ props, children }) => <div className="card"><h3>{props.title}</h3>{children}</div>,
    Button: ({ props, emit })     => <button onClick={() => emit("press")}>{props.label}</button>,
  },
});

// 3. RENDERER — turns spec JSON into a component tree
<Renderer spec={spec} registry={registry} />
```

The whole runtime is those three calls. Everything else (state, validation, AI streaming) plugs into them.

## Spec Format

Two equivalent shapes — pick whichever your AI / state store finds easier:

**Flat (preferred for streaming patches):**
```json
{
  "root": "card-1",
  "elements": {
    "card-1":   { "type": "Card",   "props": { "title": "Hi" }, "children": ["btn-1"] },
    "btn-1":    { "type": "Button", "props": { "label": "OK" }, "children": [] }
  },
  "state":    { "count": 0 }
}
```

**Tree (compact authoring):**
```json
{
  "root": {
    "type": "Card",
    "props": { "title": "Hi" },
    "children": [{ "type": "Button", "props": { "label": "OK" } }]
  }
}
```

Each element supports these top-level keys: `type`, `props`, `children`, `visible`, `repeat`, `watch`, `on` (event → action map).

## AI Integration (TypeScript)

This is the whole point of json-render. The pattern: **catalog.prompt() → AI streams JSON → `pipeJsonRender` converts to render patches → React renders progressively**.

### Server route (Next.js / Hono / any Web-handler)

```typescript
import { streamText, convertToModelMessages, createUIMessageStream,
         createUIMessageStreamResponse, type UIMessage } from "ai";
import { pipeJsonRender } from "@json-render/core";
import { catalog } from "@/lib/catalog";

export async function POST(req: Request) {
  const { messages }: { messages: UIMessage[] } = await req.json();

  const result = streamText({
    model: "anthropic/claude-haiku-4.5",     // AI Gateway: plain string, no SDK import
    system: catalog.prompt({                  // ← AI is constrained to your catalog
      mode: "inline",                         // model can talk + emit `\`\`\`spec` fence
      customRules: [
        "Use Card to group related info; never nest Card in Card.",
        "Put fetched data in /state and reference with { $state: '/path' }.",
      ],
    }),
    messages: convertToModelMessages(messages),
  });

  // pipeJsonRender turns the AI's JSON-spec stream into json-render patches
  const stream = createUIMessageStream({
    execute: async ({ writer }) => {
      writer.merge(pipeJsonRender(result.toUIMessageStream()));
    },
  });
  return createUIMessageStreamResponse({ stream });
}
```

Set `AI_GATEWAY_API_KEY` in env. Other model strings: `"openai/gpt-4o"`, `"anthropic/claude-sonnet-4-5"`, etc.

### Tool-using agent (multi-step with data fetching)

```typescript
import { ToolLoopAgent, stepCountIs } from "ai";

const agent = new ToolLoopAgent({
  model: "anthropic/claude-haiku-4.5",
  instructions: catalog.prompt({ mode: "inline", customRules: [...] }),
  tools: { getWeather, webSearch /* etc. */ },
  stopWhen: stepCountIs(5),
  temperature: 0.7,
});

const result = await agent.stream({ messages: modelMessages });
writer.merge(pipeJsonRender(result.toUIMessageStream()));
```

### Client (React)

```tsx
import { useChat } from "@ai-sdk/react";
import { JSONUIProvider, Renderer, useJsonRenderState } from "@json-render/react";

function Chat() {
  const { messages, sendMessage } = useChat();
  // pipeJsonRender embeds a `data-spec` part in each assistant message

  return (
    <JSONUIProvider registry={registry} initialState={{}}>
      {messages.map(m => m.role === "assistant"
        ? <Renderer spec={m.parts.find(p => p.type === "data-spec")?.spec} registry={registry} />
        : <UserBubble text={m.content} />)}
    </JSONUIProvider>
  );
}
```

### YAML wire format (smaller tokens, surgical edits)

Drop-in alternative to JSONL:

```typescript
import { yamlPrompt, pipeYamlRender } from "@json-render/yaml";

streamText({
  system: yamlPrompt(catalog, { mode: "inline", editModes: ["merge"] }),
  // ...
});

writer.merge(pipeYamlRender(result.toUIMessageStream(), { previousSpec: currentSpec }));
```

YAML supports four fence types: `yaml-spec` (full), `yaml-edit` (merge patch), `yaml-patch` (RFC 6902), `diff` (unified diff).

### Streaming compiler (low level)

```typescript
import { createSpecStreamCompiler } from "@json-render/core";
const compiler = createSpecStreamCompiler<MySpec>();
const { result, newPatches } = compiler.push(chunk);
const final = compiler.getResult();
```

## Component Laundry List

Counts below are unique component types per package.

### `@json-render/shadcn` (web, 36) and `@json-render/shadcn-svelte` (Svelte 5, 36)

Layout: **Card, Stack, Grid, Separator** • Navigation: **Tabs, Accordion, Collapsible, Pagination** • Overlay: **Dialog, Drawer, Tooltip, Popover, DropdownMenu** • Content: **Heading, Text, Image, Avatar, Badge, Alert, Carousel, Table** • Feedback: **Progress, Skeleton, Spinner** • Input: **Button, Link, Input, Textarea, Select, Checkbox, Radio, Switch, Slider, Toggle, ToggleGroup, ButtonGroup**

### `@json-render/react-native` (mobile, 26)

Layout: **Container, Row, Column, ScrollContainer, SafeArea, Pressable, Spacer, Divider** • Content: **Heading, Paragraph, Label, Image, Avatar, Badge, Chip** • Input: **Button, TextInput, Switch, Checkbox, Slider, SearchBar** • Feedback: **Spinner, ProgressBar** • Composite: **Card, ListItem, Modal**

### `@json-render/react-three-fiber` (3D, 44)

Geometry: **Box, Sphere, Cylinder, Cone, Plane, Capsule, Torus, TorusKnot, RoundedBox, ExtrudedText, Text3D, Cloud, GaussianSplat, Model** • Materials/effects: **GlassBox, GlassSphere, DistortSphere, MeshPortalMaterial, ReflectorPlane** • Lights: **AmbientLight, DirectionalLight, PointLight, SpotLight** • Camera/controls: **PerspectiveCamera, OrbitControls, Orbit, CameraShake** • Environment: **Stars, Sky, Sparkles, Fog, Environment, ContactShadows, Backdrop, GridHelper, HtmlLabel** • Post-processing: **EffectComposer, Bloom, Glitch, Vignette, WarpTunnel** • Animation/grouping: **Group, Float, Spin, Pulse**

### `@json-render/remotion` (video, 10)

**TitleCard, LowerThird, ImageSlide, VideoClip, TextOverlay, TypingText, QuoteCard, StatCard, SplitScreen, LogoBug** — composed inside a `composition` with `tracks` and `clips`.

### `@json-render/react-pdf` (documents, 14)

**Document, Page, View, Text, Heading, Image, Link, List, Row, Column, Spacer, Divider, Table, PageNumber**. Render with `renderToBuffer` / `renderToStream` / `renderToFile`.

### `@json-render/react-email` (HTML email, 15)

**Html, Head, Body, Container, Section, Row, Column, Heading, Text, Link, Button, Image, Hr, Preview, Markdown**. Render with `renderToHtml` / `renderToText`.

### `@json-render/ink` (terminal, 27)

**Box, Text, Heading, Card, Callout, Divider, Spacer, Newline, Markdown, Link** • Lists/tables: **List, ListItem, Table, KeyValue** • Inputs: **TextInput, Select, MultiSelect, ConfirmInput** • Status: **Badge, Spinner, ProgressBar, StatusLine, Metric, Sparkline, BarChart, Timeline, Tabs**

### `@json-render/image` (SVG/PNG via Satori, 9)

**Frame, Box, Row, Column, Heading, Text, Image, Spacer, Divider**

### `@json-render/next` (full apps)

Adds route/layout/metadata/SSR-aware components on top of the React catalog. Use `createNextApp({ spec })` server-side; the spec describes routes (`/`, `/[id]`), layouts, server actions.

### Total

~200 component implementations across renderers; ~80 unique component *names* (many — Card, Heading, Button, Image, Stack, Row, Column — appear in multiple renderers under the same name with the same shape).

## Built-in Actions

Built into the schema — appear in `catalog.prompt()` automatically; do not declare them.

### React schema (`@json-render/react/schema`)

| Action | Params | What it does |
|---|---|---|
| `setState` | `{ statePath, value }` | Set value at JSON-Pointer path |
| `pushState` | `{ statePath, value, clearStatePath? }` | Append to array; optionally clear another path |
| `removeState` | `{ statePath, index }` | Remove array item by index |
| `validateForm` | `{ statePath? }` | Run all validators, write `{ valid, errors }` to state |

### React Native schema (`@json-render/react-native/schema`)

Adds: `navigate({ screen, params? })`, `goBack({})`, `showAlert({ title, message?, buttons? })`, `share({ message?, url? })`, `openURL({ url })`, `refresh({})` plus the four state actions above.

### Custom actions

Declare in catalog `actions: { ... }` with a zod schema. Provide handlers via `<ActionProvider handlers={{ myAction: async (params, ctx) => ... }}>` (or pass `actions` on `<Renderer>` when the catalog has any).

## Dynamic Prop Expressions

Resolved at render time. Any prop value at any depth can be one of:

| Expression | Effect |
|---|---|
| `{ "$state": "/path" }` | One-way read from state |
| `{ "$bindState": "/path" }` | Two-way bind on natural value prop (`value`, `checked`, `pressed`) |
| `{ "$bindItem": "field" }` | Two-way bind to repeat-scope item field |
| `{ "$cond": <cond>, "$then": <val>, "$else": <val> }` | Pick based on visibility-style condition |
| `{ "$template": "Hi, ${/user/name}!" }` | Interpolate `${/path}` references |
| `{ "$computed": "fnName", "args": { ... } }` | Call registered computed fn |

`$cond` accepts the same condition syntax as `visible`: `{ $state: "/path" }`, `{ $state, eq: v }`, `{ $state, not: true }`, arrays for AND, `{ $and: [...] }`, `{ $or: [...] }`. Helpers: `visibility.when/unless/eq/and/or` from core.

`resolvePropValue` and `resolveElementProps` are exported for manual use.

## State Watchers & Repeats

```json
{
  "type": "Select",
  "props": { "value": { "$bindState": "/form/country" }, "options": ["US", "CA"] },
  "watch": {
    "/form/country": { "action": "loadCities", "params": { "country": { "$state": "/form/country" } } }
  }
}
```

Watchers fire on **change only**, not on initial render.

```json
{
  "type": "ListItem",
  "repeat": { "statePath": "/todos" },
  "props": { "title": { "$bindItem": "label" }, "done": { "$bindItem": "completed" } }
}
```

## Validation

Built-in checks: `required`, `email`, `url`, `numeric`, `minLength`, `maxLength`, `min`, `max`, `pattern`, `matches`, `equalTo`, `lessThan`, `greaterThan`, `requiredIf`.

```typescript
import { check } from "@json-render/core";
[check.required("Email required"), check.email("Invalid email")]
[check.matches("/form/password", "Passwords must match")]
[check.requiredIf("/form/notify", "Required when notifications on")]
```

All form components in shadcn / react-native take `checks` (array) + `validateOn` (`"change" | "blur" | "submit"`).

## Edit Modes (Refinement Workflows)

For multi-turn editing, tell the AI which patch dialect to emit:

```typescript
import { buildUserPrompt } from "@json-render/core";

buildUserPrompt({
  prompt: "add a save button",
  currentSpec: spec,
  editModes: ["patch", "merge"],   // RFC 6902, RFC 7396
});
```

| Mode | Format | Best for |
|---|---|---|
| `patch` | RFC 6902 JSON Patch (`[{ op, path, value }]`) | Surgical edits to deep paths |
| `merge` | RFC 7396 Merge Patch (partial JSON tree) | Add/replace fields |
| `diff` | Unified diff over serialized spec | Human-readable rewrites |

`pipeJsonRender` / `pipeYamlRender` recognize the AI's chosen mode automatically.

## Providers (React)

Wrap your renderer to enable features:

| Provider | Provides |
|---|---|
| `<JSONUIProvider>` | One-stop shop — wraps all four below |
| `<StateProvider initialState={...}>` (or `store={createStateStore(...)}`) | JSON-Pointer state access |
| `<ActionProvider handlers={{ ... }}>` | Custom action dispatch |
| `<VisibilityProvider>` | `visible:` evaluation |
| `<ValidationProvider>` | Form validation results |

External stores via adapters:

```typescript
import { createStateStore } from "@json-render/react";
import { reduxAdapter } from "@json-render/redux";
import { zustandAdapter } from "@json-render/zustand";
import { jotaiAdapter } from "@json-render/jotai";
import { xstateAdapter } from "@json-render/xstate";
```

## Renderer-Specific Render Calls

| Package | Output API |
|---|---|
| `@json-render/react` | `<Renderer spec={...} registry={...} />` |
| `@json-render/vue` / `svelte` / `solid` | Same shape, framework-native component |
| `@json-render/react-three-fiber` | `<ThreeCanvas spec={...} registry={...} camera={...} />` |
| `@json-render/remotion` | `<Renderer />` inside `<Player component={Renderer} inputProps={{ spec }} />` |
| `@json-render/react-pdf` | `await renderToBuffer(spec)` / `renderToStream` / `renderToFile` |
| `@json-render/react-email` | `await renderToHtml(spec)` / `renderToText(spec)` |
| `@json-render/image` | `await renderToPng(spec, { fonts })` / `renderToSvg(spec, { fonts })` |
| `@json-render/ink` | `render(<Renderer spec={...} registry={...} />)` |
| `@json-render/next` | `createNextApp({ spec })` returns app routes |
| `@json-render/mcp` | `createMcpApp({ name, version, catalog, html })` |

## Common Patterns

### Tab bar with state-driven active

```json
{
  "type": "Pressable",
  "on": { "press": { "action": "setState", "params": { "statePath": "/activeTab", "value": "home" } } },
  "props": {
    "color": {
      "$cond": { "$state": "/activeTab", "eq": "home" },
      "$then": "#007AFF", "$else": "#8E8E93"
    }
  }
}
```

### Dialog open/close via openPath

```json
{ "type": "Dialog", "props": { "title": "Confirm", "openPath": "/confirmOpen" }, "children": ["..."] }
{ "type": "Button", "props": { "label": "Open" },
  "on": { "press": { "action": "setState", "params": { "statePath": "/confirmOpen", "value": true } } } }
```

### Repeat over fetched array

```json
{ "type": "Card", "repeat": { "statePath": "/repos" },
  "props": { "title": { "$bindItem": "name" } } }
```

### State patch from AI before UI references it

In `inline` mode the AI emits patches first, then UI:

```
{"op":"add","path":"/state/repos","value":[...]}
{"op":"add","path":"/elements/list-1","value":{"type":"Card","repeat":{"statePath":"/repos"},...}}
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Importing `schema` from core | Import per-renderer: `@json-render/react/schema`, `@json-render/react-native/schema`, etc. — each has different built-ins |
| Spreading every shadcn definition | Pick only what your app uses — keeps the AI prompt small |
| Declaring `setState/pushState/removeState/validateForm` in catalog | They're built-in; declaring them is harmful (duplicates in prompt) |
| Using `statePath` prop for two-way binding | Use `{ "$bindState": "/path" }` on the value/checked/pressed prop instead |
| Putting `Card` inside `Card` | Use Stack/Separator/Heading/Accordion for sub-sections |
| `min-h-screen` / `h-screen` in shadcn UIs | UI renders inside a fixed container — use Grid/Stack with explicit gap |
| Markdown tables in `apps/web` MDX | Use HTML `<table>` — markdown tables don't render. Escape `{` as `{'{'}` in JSX |
| 3D rotation values like `[0, 0.05, 0]` | Applied per-frame at ~60fps — use 0.0005 to 0.003 |
| Forgetting `JSONUIProvider` | Components that read state will silently no-op |
| Using `npm:openai` constructor with AI Gateway | Pass model as plain string: `model: "anthropic/claude-haiku-4.5"` |
| Hardcoding ports in dev scripts | Use `portless <name> next dev` — no `--port` flag |
| Forgetting to verify package versions | Run `npm view <pkg> version` first; all `@json-render/*` share one version |

## Workflow Tips

- `pnpm type-check` after each change — catches catalog/registry mismatches
- All `@json-render/*` packages share a version — use `pnpm run version:sync`
- For deep package source, `npx opensrc <pkg>` fetches into `opensrc/`
- Devtools (`@json-render/devtools-*`) gives a live panel showing spec tree, state, action log, stream taps — drop in `<JsonRenderDevtools />` during dev
- MCP integration ships specs as interactive UI inside Claude/ChatGPT/Cursor via `createMcpApp`

## Reference

Repo: https://github.com/arthrod/json-render (cloned at this user's `valtown-deno-projects-mar14/json-render`)
- Per-package skills live at `<repo>/skills/<package>/SKILL.md` — read those for renderer specifics
- Catalog source of truth: `<repo>/packages/<package>/src/catalog.ts`
- AI examples: `<repo>/examples/chat/lib/agent.ts` and `<repo>/examples/chat/app/api/generate/route.ts`
