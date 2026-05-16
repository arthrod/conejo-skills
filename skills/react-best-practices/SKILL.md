---
name: react-best-practices
description: Use when reading or writing React components (.tsx, .jsx files with React imports).
---

# React Best Practices

## Pair with TypeScript

When working with React, always load both this skill and `typescript-best-practices` together. TypeScript patterns (type-first development, discriminated unions, Zod validation) apply to React code.

## Core Principle: Effects Are Escape Hatches

Effects let you "step outside" React to synchronize with external systems. **Most component logic should NOT use Effects.** Before writing an Effect, ask: "Is there a way to do this without an Effect?"

## Decision Tree

1. **Need to respond to user interaction?** Use event handler
2. **Need computed value from props/state?** Calculate during render
3. **Need cached expensive calculation?** Use `useMemo`
4. **Need to reset state on prop change?** Use `key` prop
5. **Need to synchronize with external system?** Use Effect with cleanup
6. **Need non-reactive code in Effect?** Use `useEffectEvent`
7. **Need mutable value that doesn't trigger render?** Use ref

## When to Use Effects

Synchronizing with **external systems**: browser APIs (WebSocket, IntersectionObserver), third-party non-React libraries, window/document event listeners, non-React DOM elements (video, maps).

## When NOT to Use Effects

- Derived state — calculate during render
- Expensive calculations — use `useMemo`
- Resetting state on prop change — use `key` prop
- Responding to user events — use event handlers
- Notifying parent of state changes — update both in the same event handler
- Chains of effects — calculate derived state and update in one event handler

## Refs

- Use for values that don't affect rendering (timer IDs, DOM node references)
- Never read or write `ref.current` during render; only in event handlers and effects
- Use ref callbacks (not `useRef` in loops) for dynamic lists
- Use `useImperativeHandle` to limit what parent can access

## Custom Hooks

- Share logic, not state — each call gets an independent state instance
- Name `useXxx` only if it actually calls other hooks; otherwise use a regular function
- Avoid lifecycle hooks (`useMount`, `useEffectOnce`) — use `useEffect` directly so the linter catches missing deps
- Keep focused on a single concrete use case

## Component Patterns

- Controlled: parent owns state; uncontrolled: component owns state
- Prefer composition with `children` over prop drilling; use Context only for truly global state
- Use `flushSync` when you need to read the DOM synchronously after a state update

See `react-patterns.md` for code examples and detailed patterns.

---

## Performance Rules (Vercel Engineering, 57 rules across 8 categories)

Apply in order of impact. Full rule details live under `rules/<name>.md` (copied from vercel-react-best-practices). Compiled doc at `AGENTS.md`.

### 1. Eliminating Waterfalls (CRITICAL) — prefix `async-`
- `async-defer-await`, `async-parallel`, `async-dependencies`, `async-api-routes`, `async-suspense-boundaries`

### 2. Bundle Size (CRITICAL) — prefix `bundle-`
- `bundle-barrel-imports`, `bundle-dynamic-imports`, `bundle-defer-third-party`, `bundle-conditional`, `bundle-preload`

### 3. Server-Side (HIGH, Next.js/RSC) — prefix `server-`
- `server-auth-actions`, `server-cache-react`, `server-cache-lru`, `server-dedup-props`, `server-serialization`, `server-parallel-fetching`, `server-after-nonblocking`

### 4. Client-Side Data Fetching (MEDIUM-HIGH) — prefix `client-`
- `client-swr-dedup`, `client-event-listeners`, `client-passive-event-listeners`, `client-localstorage-schema`

### 5. Re-render Optimization (MEDIUM) — prefix `rerender-`
- `rerender-defer-reads`, `rerender-memo`, `rerender-memo-with-default-value`, `rerender-dependencies`, `rerender-derived-state`, `rerender-derived-state-no-effect`, `rerender-functional-setstate`, `rerender-lazy-state-init`, `rerender-simple-expression-in-memo`, `rerender-move-effect-to-event`, `rerender-transitions`, `rerender-use-ref-transient-values`

### 6. Rendering (MEDIUM) — prefix `rendering-`
- `rendering-animate-svg-wrapper`, `rendering-content-visibility`, `rendering-hoist-jsx`, `rendering-svg-precision`, `rendering-hydration-no-flicker`, `rendering-hydration-suppress-warning`, `rendering-activity`, `rendering-conditional-render`, `rendering-usetransition-loading`

### 7. JavaScript Performance (LOW-MEDIUM) — prefix `js-`
- `js-batch-dom-css`, `js-index-maps`, `js-cache-property-access`, `js-cache-function-results`, `js-cache-storage`, `js-combine-iterations`, `js-length-check-first`, `js-early-exit`, `js-hoist-regexp`, `js-min-max-loop`, `js-set-map-lookups`, `js-tosorted-immutable`

### 8. Advanced (LOW) — prefix `advanced-`
- `advanced-event-handler-refs`, `advanced-init-once`, `advanced-use-latest`
