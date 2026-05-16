# Plate Comment & Suggestion Architecture

How comments, discussions, and suggestions are stored, linked, and rendered in Plate.

## Data Storage

### 1. Editor Value (Inline Marks on Text Nodes)

**Comment marks:**
```typescript
{
  text: "commented text",
  comment: true,                    // base mark (KEYS.comment)
  comment_discussion1: true,        // links to discussion ID "discussion1"
}
```

**Suggestion marks:**
```typescript
{
  text: "suggested text",
  suggestion: true,                 // base mark (KEYS.suggestion)
  suggestion_playground1: {         // structured payload
    id: "playground1",
    type: "insert" | "remove",
    userId: "alice",
    createdAt: 1706000000000
  }
}
```

### 2. Discussions Array (Plugin Options)

Stored in `discussionPlugin` options. Source of truth for discussion threads.

```typescript
type TDiscussion = {
  id: string;
  comments: TComment[];
  createdAt: Date;
  isResolved: boolean;
  userId: string;
  documentContent?: string;
  authorName?: string;       // from DOCX import
  authorInitials?: string;   // from DOCX import
};

type TComment = {
  id: string;
  contentRich: Value;
  createdAt: Date;
  discussionId: string;
  userId: string;
  isEdited: boolean;
  authorName?: string;       // bypasses user lookup
  authorInitials?: string;
};
```

### 3. Suggestions Array

Inline suggestion marks on `value` are what the Suggestion plugin reads. The suggestions array can be used by the resolver to enrich/merge.

## Plugin Responsibilities

### discussionPlugin
- **Provides options:** `users` map (avatars, names), `discussions` array, `currentUserId`
- TDiscussion matches JSON discussions entries
- TComment carries `authorName`/`authorInitials` (optional, from DOCX import)

### commentPlugin (from BaseCommentPlugin)
- Detects comment marks on text leaves
- Key APIs:
  - `api.comment.nodes({ at })` — returns NodeEntry[] for a block
  - `api.comment.nodeId(node)` — extracts discussion ID from mark key (e.g., `comment_discussion1` → `"discussion1"`)
  - `api.comment.has({ id })` — checks if any mark with that ID exists in doc
- Maintains `uniquePathMap` per discussion ID (first-block rule)

### suggestionPlugin (from BaseSuggestionPlugin)
- Detects suggestion marks on text leaves (or block data for block suggestions)
- `api.suggestion.nodes({ at })` returns suggestion nodes within current block
- Resolver (`useResolveSuggestion`) builds `TResolvedSuggestion` for rendering

## Mark → ID Linking

### Comments
```
getCommentKey(id) → `comment_${id}`

Mark key:  comment_discussion1
           ^^^^^^^^ prefix
                    ^^^^^^^^^^^ discussion ID
```

### Suggestions
```
getSuggestionKey(id) → `suggestion_${id}`

Mark key:  suggestion_playground1
           ^^^^^^^^^^ prefix
                      ^^^^^^^^^^^ suggestion ID
```

## Rendering Flow

### BlockDiscussion Component
(`apps/www/src/registry/ui/block-discussion.tsx`)

Activates on blocks with any comment or suggestion nodes (or draft comment).

1. Get comment nodes: `commentsApi.nodes({ at: blockPath })`
2. Extract IDs: `api.comment.nodeId(node)` for each node
3. Build `commentsIds` Set of IDs on this block
4. Filter discussions from plugin options:
   - `api.comment.has({ id: item.id })` — mark exists in doc
   - `commentsIds.has(item.id)` — ID present on this block
   - `uniquePathMap` ensures first-block-only display
   - `!item.isResolved` — hide resolved threads
5. Get suggestion nodes: `editor.getApi(SuggestionPlugin).suggestion.nodes({ at: blockPath })`
6. Resolve suggestions via `useResolveSuggestion(suggestionNodes, blockPath)`

### Comment Rendering (by Index)
(`apps/www/src/registry/ui/comment.tsx`)

For each TDiscussion, `discussion.comments` maps to `<Comment>`:
- `index === 0` → parent comment (shows resolve button, document content)
- `index > 0` → replies (indented, visually connected with vertical line)

### Author Display Fallback
```typescript
// Priority: direct author info → user lookup by userId
comment.authorName ?? userInfo?.name
comment.authorInitials ?? comment.authorName?.[0] ?? userInfo?.name?.[0]
```
- If `authorName`/`authorInitials` exist on TComment (e.g., from DOCX import), the UI uses them directly
- Otherwise falls back to `discussionPlugin.users` lookup by `userId`

### Badge Count
```
total badge = discussionsCount + suggestionsCount
```

## First-Block Rule

If the same discussion ID is marked across multiple blocks, only the **first encountered block** shows the discussion thread. This is enforced by `uniquePathMap` in BlockDiscussion.

## Date Normalization

`createdAt` strings from JSON are coerced to `Date` objects in `useResolvedDiscussion` before rendering.

## Key Files

| File | Purpose |
|------|---------|
| `apps/www/src/registry/components/editor/plugins/discussion-kit.tsx` | TDiscussion type, plugin config |
| `apps/www/src/registry/ui/comment.tsx` | TComment type, comment rendering |
| `apps/www/src/registry/ui/block-discussion.tsx` | Block-level discussion resolution |
| `apps/www/src/registry/ui/block-suggestion.tsx` | useResolveSuggestion hook |
| `packages/comment/src/lib/BaseCommentPlugin.ts` | Comment mark detection, nodeId extraction |
| `packages/comment/src/lib/utils/getCommentKey.ts` | `getCommentKey(id)` helper |
| `packages/suggestion/src/lib/utils/getSuggestionKeys.ts` | `getSuggestionKey(id)` helper |
| `packages/suggestion/src/lib/transforms/setSuggestionNodes.ts` | TInlineSuggestionData structure |

## DOCX Import Integration

When importing from DOCX:
1. mammoth.js emits tokens with comment/suggestion data
2. `importComments.ts` creates `DocxImportDiscussion` objects with `authorName`/`authorInitials`
3. `import-toolbar-button.tsx` converts to `TDiscussion`/`TComment` format and stores in `discussionPlugin` options
4. Comment marks are applied to editor value linking text ranges to discussion IDs
5. The existing rendering pipeline (BlockDiscussion → Comment) picks them up automatically

Reply threading from DOCX:
- Root comments (no `parentParaId`) become `index === 0` in the discussion
- Replies (have `parentParaId`) are added recursively via `addCommentRecursive` and become `index > 0`
- The UI renders them with indentation based on array index
