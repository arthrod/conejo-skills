---
name: tanstack-router
description: Type-safe routing for React and Solid applications with first-class search params, data loading, and seamless integration with the React ecosystem.
---


## Overview

TanStack Router is a fully type-safe router for React (and Solid) applications. It provides file-based routing, first-class search parameter management, built-in data loading, code splitting, and deep TypeScript integration. It serves as the routing foundation for TanStack Start (the full-stack framework).

**Package:** `@tanstack/react-router`
**CLI:** `@tanstack/router-cli` or `@tanstack/router-plugin` (Vite/Rspack/Webpack)
**Devtools:** `@tanstack/react-router-devtools`

## Installation

```bash
npm install @tanstack/react-router
# For file-based routing with Vite:
npm install -D @tanstack/router-plugin
# Or standalone CLI:
npm install -D @tanstack/router-cli
```

## Core Concepts

### Route Trees

Routes are organized in a tree structure. The root route is the top-level layout, and child routes nest underneath.

```tsx
import { createRootRoute, createRoute, createRouter } from '@tanstack/react-router'

const rootRoute = createRootRoute({
  component: RootLayout,
})

const indexRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/',
  component: HomePage,
})

const aboutRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/about',
  component: AboutPage,
})

const routeTree = rootRoute.addChildren([indexRoute, aboutRoute])
const router = createRouter({ routeTree })
```

### File-Based Routing

File-based routing automatically generates the route tree from your file structure. Configure with Vite plugin:

```ts
// vite.config.ts
import { defineConfig } from 'vite'
import { TanStackRouterVite } from '@tanstack/router-plugin/vite'

export default defineConfig({
  plugins: [
    TanStackRouterVite(),
    // ... other plugins
  ],
})
```

#### File Naming Conventions

| File Pattern | Route Type | Example Path |
|---|---|---|
| `__root.tsx` | Root layout | N/A (wraps all) |
| `index.tsx` | Index route | `/` |
| `about.tsx` | Static route | `/about` |
| `$postId.tsx` | Dynamic param | `/posts/$postId` |
| `posts.tsx` | Layout route | `/posts/*` (layout) |
| `posts/index.tsx` | Nested index | `/posts` |
| `posts/$postId.tsx` | Nested dynamic | `/posts/123` |
| `posts_.$postId.tsx` | Pathless layout | `/posts/123` (different layout) |
| `_layout.tsx` | Pathless layout | N/A (groups routes) |
| `_layout/dashboard.tsx` | Grouped route | `/dashboard` |
| `$.tsx` | Splat/catch-all | `/*` |
| `posts.$postId.edit.tsx` | Dot notation | `/posts/123/edit` |

#### Special Prefixes
- `_` prefix: Pathless routes (layout groups without URL segment)
- `$` prefix: Dynamic path parameters
- `(folder)` parentheses: Route groups (organizational, no URL impact)

### Route Configuration

Each route can define:

```tsx
// routes/posts.$postId.tsx
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/posts/$postId')({
  // Validation for path params
  params: {
    parse: (params) => ({ postId: Number(params.postId) }),
    stringify: (params) => ({ postId: String(params.postId) }),
  },

  // Search params validation
  validateSearch: (search: Record<string, unknown>) => {
    return {
      page: Number(search.page ?? 1),
      filter: (search.filter as string) || '',
    }
  },

  // Data loading
  loader: async ({ params, context, abortController }) => {
    return fetchPost(params.postId)
  },

  // Loader dependencies (re-run loader when these change)
  loaderDeps: ({ search }) => ({ page: search.page }),

  // Stale time for cached loader data
  staleTime: 5_000,

  // Preloading
  preloadStaleTime: 30_000,

  // Error component
  errorComponent: PostErrorComponent,

  // Pending/loading component
  pendingComponent: PostLoadingComponent,

  // 404 component
  notFoundComponent: PostNotFoundComponent,

  // Before load hook (authentication, redirects)
  beforeLoad: async ({ context, location }) => {
    if (!context.auth.isAuthenticated) {
      throw redirect({
        to: '/login',
        search: { redirect: location.href },
      })
    }
  },

  // Head/meta management
  head: () => ({
    meta: [{ title: 'Post Details' }],
  }),

  // Component
  component: PostComponent,
})

function PostComponent() {
  const { postId } = Route.useParams()
  const post = Route.useLoaderData()
  const { page, filter } = Route.useSearch()

  return <div>{post.title}</div>
}
```

## Data Loading

### Route Loaders

```tsx
export const Route = createFileRoute('/posts')({
  loader: async ({ context }) => {
    // Access router context (e.g., queryClient)
    const posts = await context.queryClient.ensureQueryData({
      queryKey: ['posts'],
      queryFn: fetchPosts,
    })
    return { posts }
  },
  component: PostsComponent,
})

function PostsComponent() {
  const { posts } = Route.useLoaderData()
  // ...
}
```

### Loader Dependencies

Control when loaders re-execute:

```tsx
export const Route = createFileRoute('/posts')({
  loaderDeps: ({ search: { page, filter } }) => ({ page, filter }),
  loader: async ({ deps: { page, filter } }) => {
    return fetchPosts({ page, filter })
  },
})
```

### Deferred Data Loading

Stream non-critical data:

```tsx
import { Await, defer } from '@tanstack/react-router'

export const Route = createFileRoute('/dashboard')({
  loader: async () => {
    const criticalData = await fetchCriticalData()
    const deferredData = defer(fetchSlowData())
    return { criticalData, deferredData }
  },
  component: DashboardComponent,
})

function DashboardComponent() {
  const { criticalData, deferredData } = Route.useLoaderData()

  return (
    <div>
      <CriticalSection data={criticalData} />
      <Suspense fallback={<Loading />}>
        <Await promise={deferredData}>
          {(data) => <SlowSection data={data} />}
        </Await>
      </Suspense>
    </div>
  )
}
```

### Context-Based Data Loading

Provide shared dependencies via router context:

```tsx
// Create router with context
const router = createRouter({
  routeTree,
  context: {
    queryClient,
    auth: undefined!, // Will be provided by RouterProvider
  },
})

// In root/app component
function App() {
  const auth = useAuth()
  return <RouterProvider router={router} context={{ auth }} />
}

// In routes
export const Route = createFileRoute('/protected')({
  beforeLoad: ({ context }) => {
    if (!context.auth.user) throw redirect({ to: '/login' })
  },
  loader: ({ context }) => {
    return context.queryClient.ensureQueryData(userQueryOptions())
  },
})
```

## Search Parameters

### Validation

```tsx
import { z } from 'zod'

const postSearchSchema = z.object({
  page: z.number().default(1),
  filter: z.string().default(''),
  sort: z.enum(['date', 'title']).default('date'),
})

export const Route = createFileRoute('/posts')({
  validateSearch: postSearchSchema,
  // Or manual validation:
  // validateSearch: (search) => postSearchSchema.parse(search),
})
```

### Reading Search Params

```tsx
function PostsComponent() {
  // From route
  const { page, filter, sort } = Route.useSearch()

  // Or from any component with useSearch hook
  const search = useSearch({ from: '/posts' })
}
```

### Updating Search Params

```tsx
import { useNavigate } from '@tanstack/react-router'

function Pagination() {
  const navigate = useNavigate()
  const { page } = Route.useSearch()

  return (
    <button
      onClick={() =>
        navigate({
          search: (prev) => ({ ...prev, page: prev.page + 1 }),
        })
      }
    >
      Next Page
    </button>
  )
}

// Or via Link component
<Link
  to="/posts"
  search={(prev) => ({ ...prev, page: 2 })}
>
  Page 2
</Link>
```

### Search Param Options

```tsx
const router = createRouter({
  routeTree,
  // Custom serialization
  search: {
    strict: true, // Reject unknown params
  },
  // Default search param serializer
  stringifySearch: defaultStringifySearch,
  parseSearch: defaultParseSearch,
})
```

## Navigation

### Link Component

```tsx
import { Link } from '@tanstack/react-router'

// Static route
<Link to="/about">About</Link>

// Dynamic route with params
<Link to="/posts/$postId" params={{ postId: '123' }}>
  Post 123
</Link>

// With search params
<Link to="/posts" search={{ page: 2, filter: 'react' }}>
  Page 2
</Link>

// Active link styling
<Link
  to="/posts"
  activeProps={{ className: 'active' }}
  inactiveProps={{ className: 'inactive' }}
  activeOptions={{ exact: true }}
>
  Posts
</Link>

// Preloading
<Link to="/posts" preload="intent">Posts</Link>
<Link to="/dashboard" preload="viewport">Dashboard</Link>

// Hash
<Link to="/docs" hash="api-reference">API Reference</Link>
```

### Programmatic Navigation

```tsx
import { useNavigate, useRouter } from '@tanstack/react-router'

function MyComponent() {
  const navigate = useNavigate()
  const router = useRouter()

  // Navigate to a route
  navigate({ to: '/posts', search: { page: 1 } })

  // Navigate with replace
  navigate({ to: '/posts', replace: true })

  // Relative navigation
  navigate({ to: '.', search: (prev) => ({ ...prev, page: 2 }) })

  // Go back/forward
  router.history.back()
  router.history.forward()

  // Invalidate and reload current route
  router.invalidate()
}
```

### Redirects

```tsx
import { redirect } from '@tanstack/react-router'

// In beforeLoad or loader
throw redirect({
  to: '/login',
  search: { redirect: location.href },
  // Optional status code
  statusCode: 301, // Permanent redirect (SSR)
})
```

### Navigation Blocking

```tsx
import { useBlocker } from '@tanstack/react-router'

function FormComponent() {
  const [isDirty, setIsDirty] = useState(false)

  useBlocker({
    shouldBlockFn: () => isDirty,
    withResolver: true, // Shows confirm dialog
  })

  // Or with custom UI
  const { proceed, reset, status } = useBlocker({
    shouldBlockFn: () => isDirty,
  })

  if (status === 'blocked') {
    return (
      <div>
        <p>Are you sure you want to leave?</p>
        <button onClick={proceed}>Leave</button>
        <button onClick={reset}>Stay</button>
      </div>
    )
  }
}
```

## Code Splitting

### Automatic (File-Based Routing)

With file-based routing, create a lazy file:

```
routes/
  posts.tsx          # Critical: loader, beforeLoad, meta
  posts.lazy.tsx     # Lazy: component, pendingComponent, errorComponent
```

```tsx
// posts.tsx (loaded eagerly)
export const Route = createFileRoute('/posts')({
  loader: () => fetchPosts(),
})

// posts.lazy.tsx (loaded lazily)
import { createLazyFileRoute } from '@tanstack/react-router'

export const Route = createLazyFileRoute('/posts')({
  component: PostsComponent,
  pendingComponent: PostsLoading,
  errorComponent: PostsError,
})
```

### Manual Code Splitting

```tsx
const postsRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/posts',
  loader: () => fetchPosts(),
}).lazy(() => import('./posts.lazy').then((d) => d.Route))
```

## Preloading

```tsx
// Router-level defaults
const router = createRouter({
  routeTree,
  defaultPreload: 'intent', // 'intent' | 'viewport' | 'render' | false
  defaultPreloadStaleTime: 30_000, // 30 seconds
})

// Route-level
export const Route = createFileRoute('/posts/$postId')({
  // Stale time for the loader data
  staleTime: 5_000,
  // How long preloaded data stays fresh
  preloadStaleTime: 30_000,
})

// Link-level
<Link to="/posts" preload="intent" preloadDelay={100}>
  Posts
</Link>
```

## Type Safety

### Register Router Type

```tsx
// Declare module for type inference
declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
}
```

### Type-Safe Hooks

All hooks are fully typed based on the route tree:

```tsx
// useParams - typed to route's params
const { postId } = useParams({ from: '/posts/$postId' })

// useSearch - typed to route's search schema
const { page } = useSearch({ from: '/posts' })

// useLoaderData - typed to loader return
const data = useLoaderData({ from: '/posts/$postId' })

// useRouteContext - typed to route context
const { auth } = useRouteContext({ from: '/protected' })
```

### Route Generics

```tsx
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/posts/$postId')({
  // TypeScript infers:
  // params: { postId: string }
  // search: validated search schema type
  // loaderData: return type of loader
  // context: router context type
})
```

## Authenticated Routes

```tsx
// __root.tsx
export const Route = createRootRouteWithContext<{
  auth: AuthContext
}>()({
  component: RootComponent,
})

// _authenticated.tsx (pathless layout for auth)
export const Route = createFileRoute('/_authenticated')({
  beforeLoad: ({ context, location }) => {
    if (!context.auth.isAuthenticated) {
      throw redirect({
        to: '/login',
        search: { redirect: location.href },
      })
    }
  },
})

// _authenticated/dashboard.tsx
export const Route = createFileRoute('/_authenticated/dashboard')({
  component: Dashboard, // Only accessible when authenticated
})
```

## Scroll Restoration

```tsx
const router = createRouter({
  routeTree,
  // Enable scroll restoration
  defaultScrollRestoration: true,
})

// Or per-route
export const Route = createFileRoute('/posts')({
  // Scroll to top on navigation
  scrollRestoration: true,
})

// Custom scroll restoration key
<ScrollRestoration
  getKey={(location) => location.pathname}
/>
```

## Route Masking

Display a different URL than the actual route:

```tsx
<Link
  to="/photos/$photoId"
  params={{ photoId: photo.id }}
  mask={{ to: '/photos', search: { photoId: photo.id } }}
>
  View Photo
</Link>

// Or programmatically
navigate({
  to: '/photos/$photoId',
  params: { photoId: photo.id },
  mask: { to: '/photos', search: { photoId: photo.id } },
})
```

## Not Found Handling

```tsx
// Global 404
const router = createRouter({
  routeTree,
  defaultNotFoundComponent: () => <div>Page not found</div>,
})

// Route-level 404
export const Route = createFileRoute('/posts/$postId')({
  loader: async ({ params }) => {
    const post = await fetchPost(params.postId)
    if (!post) throw notFound()
    return post
  },
  notFoundComponent: () => <div>Post not found</div>,
})
```

## Head Management

```tsx
export const Route = createFileRoute('/posts/$postId')({
  head: ({ loaderData }) => ({
    meta: [
      { title: loaderData.title },
      { name: 'description', content: loaderData.excerpt },
      { property: 'og:title', content: loaderData.title },
    ],
    links: [
      { rel: 'canonical', href: `https://example.com/posts/${loaderData.id}` },
    ],
  }),
})
```

## Integration with TanStack Query

```tsx
import { queryOptions } from '@tanstack/react-query'

const postsQueryOptions = queryOptions({
  queryKey: ['posts'],
  queryFn: fetchPosts,
})

export const Route = createFileRoute('/posts')({
  loader: ({ context: { queryClient } }) => {
    // Ensure data is in cache, won't refetch if fresh
    return queryClient.ensureQueryData(postsQueryOptions)
  },
  component: PostsComponent,
})

function PostsComponent() {
  // Use the same query options for reactive updates
  const { data: posts } = useSuspenseQuery(postsQueryOptions)
  return <PostsList posts={posts} />
}
```

## Router Hooks Reference

| Hook | Purpose |
|------|---------|
| `useRouter()` | Access router instance |
| `useRouterState()` | Subscribe to router state |
| `useParams()` | Get route path params |
| `useSearch()` | Get validated search params |
| `useLoaderData()` | Get route loader data |
| `useRouteContext()` | Get route context |
| `useNavigate()` | Get navigate function |
| `useLocation()` | Get current location |
| `useMatches()` | Get all matched routes |
| `useMatch()` | Get specific route match |
| `useBlocker()` | Block navigation |
| `useLinkProps()` | Get link props for custom components |
| `useMatchRoute()` | Check if a route matches |

## Best Practices

1. **Use file-based routing** for most applications - it's simpler and auto-generates the route tree
2. **Validate search params** with Zod or custom validators for type safety
3. **Use `loaderDeps`** to control when loaders re-execute based on search param changes
4. **Leverage context** for dependency injection (QueryClient, auth state)
5. **Use `beforeLoad`** for authentication guards, not in components
6. **Separate critical vs lazy code** - keep loaders in the main file, components in `.lazy.tsx`
7. **Use `preload="intent"`** on Links for perceived performance
8. **Use `staleTime`** to prevent unnecessary refetches during navigation
9. **Register the router type** for full TypeScript inference across the app
10. **Use `notFound()`** instead of conditional rendering for 404 states
11. **Colocate search param logic** with routes that own them
12. **Use pathless layouts** (`_authenticated`) for shared auth/layout logic without URL segments

## Common Pitfalls

- Forgetting to register the router type (`declare module`)
- Not using `loaderDeps` when loader depends on search params (causes stale data)
- Putting auth checks in components instead of `beforeLoad` (flash of protected content)
- Not handling the loading state with `pendingComponent`
- Using `useEffect` for data fetching instead of route loaders
- Mutating search params directly instead of using navigate/Link
- Not wrapping the app with `RouterProvider`
- Forgetting `getParentRoute` in code-based route definitions

<!-- cross-ref:start -->

## See also (related skills — TanStack family)

If your issue relates to:
- **best practices — search params, data loading, navigation** — check `tanstack-router-best-practices` if appropriate.
- **headless virtualization for large lists at 60fps** — check `tanstack-virtual` if appropriate.

<!-- cross-ref:end -->


---

# TanStack Virtual

_Merged from former `tanstack-virtual` skill — headless virtualization for large lists at 60fps._



## Overview

TanStack Virtual provides virtualization logic for rendering only visible items in large lists, grids, and tables. It calculates which items are in the viewport and positions them with absolute positioning, keeping DOM node count minimal regardless of dataset size.

**Package:** `@tanstack/react-virtual`
**Core:** `@tanstack/virtual-core` (framework-agnostic)

## Installation

```bash
npm install @tanstack/react-virtual
```

## Core Pattern

```tsx
import { useVirtualizer } from '@tanstack/react-virtual'

function VirtualList() {
  const parentRef = useRef<HTMLDivElement>(null)

  const virtualizer = useVirtualizer({
    count: 10000,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 35, // estimated row height in px
    overscan: 5,
  })

  return (
    <div ref={parentRef} style={{ height: '400px', overflow: 'auto' }}>
      <div
        style={{
          height: `${virtualizer.getTotalSize()}px`,
          width: '100%',
          position: 'relative',
        }}
      >
        {virtualizer.getVirtualItems().map((virtualItem) => (
          <div
            key={virtualItem.key}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: `${virtualItem.size}px`,
              transform: `translateY(${virtualItem.start}px)`,
            }}
          >
            Row {virtualItem.index}
          </div>
        ))}
      </div>
    </div>
  )
}
```

## Virtualizer Options

### Required

| Option | Type | Description |
|--------|------|-------------|
| `count` | `number` | Total number of items |
| `getScrollElement` | `() => Element \| null` | Returns scroll container |
| `estimateSize` | `(index) => number` | Estimated item size (overestimate recommended) |

### Optional

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `overscan` | `number` | `1` | Extra items rendered beyond viewport |
| `horizontal` | `boolean` | `false` | Horizontal virtualization |
| `gap` | `number` | `0` | Gap between items (px) |
| `lanes` | `number` | `1` | Number of lanes (masonry/grid) |
| `paddingStart` | `number` | `0` | Padding before first item |
| `paddingEnd` | `number` | `0` | Padding after last item |
| `scrollPaddingStart` | `number` | `0` | Offset for scrollTo positioning |
| `scrollPaddingEnd` | `number` | `0` | Offset for scrollTo positioning |
| `initialOffset` | `number` | `0` | Starting scroll position |
| `initialRect` | `Rect` | - | Initial dimensions (SSR) |
| `enabled` | `boolean` | `true` | Enable/disable |
| `getItemKey` | `(index) => Key` | `(i) => i` | Stable key for items |
| `rangeExtractor` | `(range) => number[]` | default | Custom visible indices |
| `scrollToFn` | `(offset, options, instance) => void` | default | Custom scroll behavior |
| `measureElement` | `(el, entry, instance) => number` | default | Custom measurement |
| `onChange` | `(instance, sync) => void` | - | State change callback |
| `isScrollingResetDelay` | `number` | `150` | Delay before scroll complete |

## Virtualizer API

```typescript
// Get visible items
virtualizer.getVirtualItems(): VirtualItem[]

// Get total scrollable size
virtualizer.getTotalSize(): number

// Scroll to specific index
virtualizer.scrollToIndex(index, { align: 'start' | 'center' | 'end' | 'auto', behavior: 'auto' | 'smooth' })

// Scroll to offset
virtualizer.scrollToOffset(offset, options)

// Force recalculation
virtualizer.measure()
```

## VirtualItem Properties

```typescript
interface VirtualItem {
  key: Key           // Unique key
  index: number      // Index in source data
  start: number      // Pixel offset (use for transform)
  end: number        // End pixel offset
  size: number       // Item dimension
  lane: number       // Lane index (multi-column)
}
```

## Dynamic/Variable Heights

Use `measureElement` ref for items with unknown heights:

```tsx
const virtualizer = useVirtualizer({
  count: items.length,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 50, // overestimate
})

{virtualizer.getVirtualItems().map((virtualItem) => (
  <div
    key={virtualItem.key}
    data-index={virtualItem.index}  // REQUIRED for measurement
    ref={virtualizer.measureElement} // Attach for dynamic measurement
    style={{
      position: 'absolute',
      top: 0,
      left: 0,
      width: '100%',
      transform: `translateY(${virtualItem.start}px)`,
      // Do NOT set fixed height - let content determine it
    }}
  >
    {items[virtualItem.index].content}
  </div>
))}
```

## Horizontal Virtualization

```tsx
const virtualizer = useVirtualizer({
  count: columns.length,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 100,
  horizontal: true,
})

// Use width for container, translateX for positioning
<div style={{ width: `${virtualizer.getTotalSize()}px`, position: 'relative' }}>
  {virtualizer.getVirtualItems().map((item) => (
    <div style={{
      position: 'absolute',
      height: '100%',
      width: `${item.size}px`,
      transform: `translateX(${item.start}px)`,
    }}>
      Column {item.index}
    </div>
  ))}
</div>
```

## Grid Virtualization (Two Virtualizers)

```tsx
function VirtualGrid() {
  const parentRef = useRef<HTMLDivElement>(null)

  const rowVirtualizer = useVirtualizer({
    count: 10000,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 35,
    overscan: 5,
  })

  const columnVirtualizer = useVirtualizer({
    count: 10000,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 100,
    horizontal: true,
    overscan: 5,
  })

  return (
    <div ref={parentRef} style={{ height: '500px', width: '500px', overflow: 'auto' }}>
      <div style={{
        height: `${rowVirtualizer.getTotalSize()}px`,
        width: `${columnVirtualizer.getTotalSize()}px`,
        position: 'relative',
      }}>
        {rowVirtualizer.getVirtualItems().map((virtualRow) => (
          <Fragment key={virtualRow.key}>
            {columnVirtualizer.getVirtualItems().map((virtualColumn) => (
              <div
                key={virtualColumn.key}
                style={{
                  position: 'absolute',
                  width: `${virtualColumn.size}px`,
                  height: `${virtualRow.size}px`,
                  transform: `translateX(${virtualColumn.start}px) translateY(${virtualRow.start}px)`,
                }}
              >
                Cell {virtualRow.index},{virtualColumn.index}
              </div>
            ))}
          </Fragment>
        ))}
      </div>
    </div>
  )
}
```

## Window Scrolling

```tsx
import { useWindowVirtualizer } from '@tanstack/react-virtual'

function WindowList() {
  const listRef = useRef<HTMLDivElement>(null)

  const virtualizer = useWindowVirtualizer({
    count: 10000,
    estimateSize: () => 45,
    overscan: 5,
    scrollMargin: listRef.current?.offsetTop ?? 0,
  })

  return (
    <div ref={listRef}>
      <div style={{
        height: `${virtualizer.getTotalSize()}px`,
        position: 'relative',
      }}>
        {virtualizer.getVirtualItems().map((item) => (
          <div
            key={item.key}
            style={{
              position: 'absolute',
              height: `${item.size}px`,
              transform: `translateY(${item.start - virtualizer.options.scrollMargin}px)`,
            }}
          >
            Row {item.index}
          </div>
        ))}
      </div>
    </div>
  )
}
```

## Infinite Scrolling

```tsx
import { useVirtualizer } from '@tanstack/react-virtual'
import { useInfiniteQuery } from '@tanstack/react-query'

function InfiniteList() {
  const { data, fetchNextPage, hasNextPage, isFetchingNextPage } = useInfiniteQuery({
    queryKey: ['items'],
    queryFn: ({ pageParam = 0 }) => fetchItems(pageParam),
    getNextPageParam: (lastPage) => lastPage.nextCursor,
  })

  const allItems = data?.pages.flatMap((page) => page.items) ?? []

  const virtualizer = useVirtualizer({
    count: hasNextPage ? allItems.length + 1 : allItems.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 50,
    overscan: 5,
  })

  useEffect(() => {
    const items = virtualizer.getVirtualItems()
    const lastItem = items[items.length - 1]
    if (lastItem && lastItem.index >= allItems.length - 1 && hasNextPage && !isFetchingNextPage) {
      fetchNextPage()
    }
  }, [virtualizer.getVirtualItems(), hasNextPage, isFetchingNextPage, allItems.length])

  // Render virtual items, show loader row for last item if loading
}
```

## Sticky Items

```tsx
import { defaultRangeExtractor, Range } from '@tanstack/react-virtual'

const stickyIndexes = [0, 10, 20, 30] // Header indices

const virtualizer = useVirtualizer({
  count: 1000,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 50,
  rangeExtractor: useCallback((range: Range) => {
    const next = new Set([...stickyIndexes, ...defaultRangeExtractor(range)])
    return [...next].sort((a, b) => a - b)
  }, [stickyIndexes]),
})

// Render sticky items with position: sticky; top: 0; zIndex: 1
```

## Smooth Scrolling

```tsx
const virtualizer = useVirtualizer({
  scrollToFn: (offset, { behavior }, instance) => {
    if (behavior === 'smooth') {
      // Custom easing animation
      instance.scrollElement?.scrollTo({ top: offset, behavior: 'smooth' })
    } else {
      instance.scrollElement?.scrollTo({ top: offset })
    }
  },
})

// Usage
virtualizer.scrollToIndex(500, { align: 'center', behavior: 'smooth' })
```

## Best Practices

1. **Overestimate `estimateSize`** - prevents scroll jumps (items shrinking causes issues)
2. **Increase `overscan`** (3-5) to reduce blank flashing during fast scrolling
3. **Use `transform: translateY()`** over `top` for GPU-composited positioning
4. **Add `data-index` attribute** when using `measureElement` for dynamic sizing
5. **Don't set fixed height** on dynamically measured items
6. **Use `getItemKey`** for stable keys when items can reorder
7. **Use `gap` option** instead of margins (margins interfere with measurement)
8. **Use `paddingStart/End`** instead of CSS padding on the container
9. **Use `enabled: false`** to pause when the list is hidden
10. **Memoize callbacks** (`estimateSize`, `getItemKey`, `rangeExtractor`)
11. **Use `will-change: transform`** CSS on items for GPU acceleration

## Common Pitfalls

- Setting fixed height on dynamically measured items
- Using CSS margins instead of the `gap` option
- Forgetting `data-index` with `measureElement`
- Not providing `position: relative` on the inner container
- Underestimating `estimateSize` (causes scroll jumps)
- Setting `overscan` too low for fast scrolling (blank items)
- Forgetting to subtract `scrollMargin` from `translateY` in window scrolling
- Not memoizing the `estimateSize` function (causes re-renders)

<!-- cross-ref:start -->

## See also (related skills — TanStack family)

If your issue relates to:
- **type-safe routing (React/Solid)** — check `tanstack-router` if appropriate.
- **best practices — search params, data loading, navigation** — check `tanstack-router-best-practices` if appropriate.

<!-- cross-ref:end -->

