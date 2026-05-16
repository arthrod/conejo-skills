---
name: pr-docx
description: Comprehensive DOCX import/export handling for Plate editor with tracked changes and comments. Use when implementing or debugging DOCX file operations, mammoth.js modifications, suggestion/comment import from Word, or export of Plate content to Word format. Triggers on requests involving DOCX import, export, tracked changes, Word comments, mammoth.js, or round-trip document fidelity. This skill ensures the agent understands the NON-NEGOTIABLE requirements for seamless Word ↔ Plate integration.
---

# DOCX Import/Export for Plate Editor

## CRITICAL UNDERSTANDING

This skill provides comprehensive guidance for DOCX import/export with **absolute requirements** that must be followed. Read this entire skill before making any changes to DOCX-related code.

## The Non-Negotiable Principle: "NO MATTER WHAT"

**"NO MATTER WHAT"** is an **absolutist requirement**. Content is SACRED. Metadata is secondary.

### Priority Hierarchy

```
PRIORITY 1 (REQUIRED): LOCATION
  → We MUST know WHERE the comment/change applies
  → Without location, we cannot place the annotation - ONLY valid skip

PRIORITY 2 (REQUIRED): CONTENT
  → The comment TEXT or changed TEXT must be preserved

PRIORITY 3 (BEST EFFORT): METADATA
  → Author → Use if available, else "imported-unknown"
  → Date → Use if available, else Date.now()
```

### The Golden Rules

| Scenario | Action | Skip? |
|----------|--------|-------|
| Has location, has author, has date | Import fully | NO |
| Has location, NO author | Import with `"imported-unknown"` | NO |
| Has location, NO date | Import with `Date.now()` | NO |
| Has location, NO text (comment) | Import with empty text | NO |
| **Tracked change:** NO start OR end | Log warning, clean up | **YES** |
| **Comment:** NO start | Log warning, clean up | **YES** |
| **Comment:** Has start, NO end | Use start as point comment | **NO - infer end** |

### Special: Comments With Partial Markers (Golden Rule)

**A comment needs ANY location marker to be preserved.** The Golden Rule:

| Scenario | Action |
|----------|--------|
| Has start, no end | end = start → point comment |
| Has end, no start | start = end → point comment |
| Has neither | Skip (only valid skip) |

```typescript
// Golden rule: if we have ANY location marker, preserve the comment
if (!startTokenRange && !endTokenRange) {
  // Only skip when we have NO markers at all
  if (process.env.NODE_ENV !== "production") {
    console.warn("[DOCX Import] Skipping comment with no location markers:", comment.id);
  }
  continue;
}

// Use whichever marker we have, fallback to the other for point comments
const effectiveStartTokenRange = startTokenRange ?? endTokenRange;
const effectiveEndTokenRange = endTokenRange ?? startTokenRange;
```

### In Code Terms

```typescript
// COMMENTS: Always import if we have location
if (!startTokenRange || !endTokenRange) {
  // NO LOCATION = only valid skip
  console.warn("Skipping - no location:", comment.id);
  continue;
}
// Everything else? IMPORT with defaults
const userId = comment.authorName ?? "imported-unknown";
const date = comment.date ? Date.parse(comment.date) : Date.now();
// ... create discussion

// TRACKED CHANGES: Same principle
if (!changeRange) {
  console.warn("Skipping - no location:", change.id);
  continue;
}
const suggestion = {
  userId: change.author ?? "imported-unknown",
  createdAt: change.date ? Date.parse(change.date) : Date.now(),
  // ... rest
};
```

### What This Means

1. **Every tracked change MUST be preserved** - if we have location
2. **Every comment MUST be preserved** - if we have location
3. **Authors do NOT need to exist** - use names directly, no lookup
4. **Dates do NOT need to exist** - use current timestamp as fallback
5. **No silent failures** - log warnings but STILL import with defaults
6. **Round-trip fidelity** - Import → Export → Import must preserve

### CRITICAL: Precision vs. Preservation

```
┌─────────────────────────────────────────────────────────┐
│  PRESERVATION > PRECISION                               │
│                                                         │
│  Better to import with imperfect metadata               │
│  than lose content for "cleaner" code.                  │
└─────────────────────────────────────────────────────────┘
```

**Any change that increases risk of losing comments/tracked changes for precision MUST:**

1. **Have mandatory fallback logging:**
   ```typescript
   if (!meetsStrictCriteria(change)) {
     console.warn("[DOCX Import] Precision check failed, using fallback:", {
       id: change.id,
       reason: "...",
       originalData: change,
     });
     importWithDefaults(change);  // STILL IMPORT IT
   }
   ```

2. **Be implemented ONLY after careful research:**
   - Review DOCX specification for edge cases
   - Test with Word, LibreOffice, AND Google Docs exports
   - Verify NO content is lost in any scenario
   - Document WHY the precision is needed

3. **Never skip without logging:**
   ```typescript
   // ❌ WRONG - Silent skip
   if (!valid) continue;

   // ✅ CORRECT - Fallback with logging
   if (!valid) {
     console.warn("[DOCX Import] Using fallback for:", id);
     importWithDefaults(item);
   }
   ```

**Review checklist for precision changes:**
- [ ] Has fallback that preserves content?
- [ ] Logs when fallback is used?
- [ ] Tested with malformed documents?
- [ ] Is precision necessary or just "nice to have"?
- [ ] Could this cause silent data loss?

## Architecture Overview

```
                    IMPORT FLOW
┌──────────┐    ┌─────────────┐    ┌────────────────┐    ┌─────────────┐
│  .docx   │───►│ mammoth.js  │───►│ HTML + Tokens  │───►│Plate Editor │
│  file    │    │ body-reader │    │ [[DOCX_*:...]] │    │ Suggestions │
└──────────┘    │ doc-to-html │    └────────────────┘    │ Comments    │
                └─────────────┘                          └─────────────┘

                    EXPORT FLOW
┌─────────────┐    ┌────────────────┐    ┌───────────────┐    ┌──────────┐
│Plate Editor │───►│ Serialize to   │───►│ docx-export   │───►│  .docx   │
│ Suggestions │    │ Word-safe HTML │    │ kit           │    │  file    │
│ Comments    │    │ <ins>/<del>    │    └───────────────┘    └──────────┘
└─────────────┘    │ Word comments  │
                   └────────────────┘
```

## Token System

mammoth.js emits tokens that import-toolbar-button.tsx parses:

### CRITICAL: Token Positioning with findHtmlPath().wrap()

**Tokens MUST be positioned inline with text for Plate to find them.**

In mammoth.js, element handlers should use `findHtmlPath(element, htmlPaths.empty).wrap()` to ensure tokens are emitted in the correct position within the document structure:

```javascript
// ✅ CORRECT - Token positioned inline with content
commentRangeStart: function (element, messages, options) {
  return findHtmlPath(element, htmlPaths.empty).wrap(function () {
    var token = DOCX_COMMENT_START_TOKEN_PREFIX + payload + DOCX_COMMENT_TOKEN_SUFFIX;
    return [Html.text(token)];
  });
},

// ❌ WRONG - Token may appear outside paragraph structure
commentRangeStart: function (element, messages, options) {
  var token = DOCX_COMMENT_START_TOKEN_PREFIX + payload + DOCX_COMMENT_TOKEN_SUFFIX;
  return [Html.text(token)];  // No wrap = wrong position
},
```

**Why this matters for Plate:**

```
WITHOUT wrap():
  <p>Hello</p>[[DOCX_CMT_START:...]]<p>world</p>
  └─ Token outside paragraph
  └─ After deserialization: token in wrong node or lost
  └─ searchRange() fails → comment not imported

WITH wrap():
  <p>Hello[[DOCX_CMT_START:...]]world</p>
  └─ Token inline with text
  └─ After deserialization: token in same text node as content
  └─ searchRange() succeeds → comment imported correctly
```

**The Flow:**
1. mammoth.js emits `[[DOCX_CMT_START:{...}]]` token inline with text
2. `cleanDocx()` + `html.deserialize()` creates Plate nodes
3. Token text is in the same node as the annotated content
4. `searchRange()` finds the token boundaries
5. Comment marks are applied to the correct range

**Rule: All token-emitting handlers must use findHtmlPath().wrap()**
- `commentRangeStart` → `findHtmlPath(element, htmlPaths.empty).wrap()`
- `commentRangeEnd` → `findHtmlPath(element, htmlPaths.empty).wrap()`
- `inserted` → Already wraps children correctly
- `deleted` → Already wraps children correctly

| Token | Purpose |
|-------|---------|
| `[[DOCX_INS_START:{...}]]` | Start of insertion (tracked change) |
| `[[DOCX_INS_END:id]]` | End of insertion |
| `[[DOCX_DEL_START:{...}]]` | Start of deletion (tracked change) |
| `[[DOCX_DEL_END:id]]` | End of deletion |
| `[[DOCX_CMT_START:{...}]]` | Start of comment range |
| `[[DOCX_CMT_END:id]]` | End of comment range |

Payload structure (JSON, URL-encoded):
```json
{
  "id": "unique-id",
  "author": "Author Name",
  "date": "2024-01-15T10:30:00Z"
}
```

For comments, additional fields:
```json
{
  "id": "0",
  "authorName": "John Doe",
  "authorInitials": "JD",
  "date": "2024-01-15T10:30:00Z",
  "text": "Comment content here"
}
```

## Packages Overview

The codebase uses multiple packages for DOCX handling. Understanding their roles prevents conflicts:

| Package | Location | Purpose | Direction |
|---------|----------|---------|-----------|
| **mammoth.js** | `packages/mammoth.js/` | DOCX → HTML conversion | Import |
| **html-to-docx** | `plugin/docx-export/packages/html-to-docx/` | HTML → DOCX conversion | Export |
| **docxjs** | `packages/docxjs/` | DOCX preview/rendering | Preview |
| **@platejs/docx** | `node_modules/@platejs/docx/` | Plate DOCX utilities | Both |

### mammoth.js (Custom Fork)

**Purpose:** Convert DOCX to HTML with embedded tokens for tracked changes and comments.

**Key modifications:**
- `lib/docx/body-reader.js` - Parses `w:ins`, `w:del`, `w:commentRangeStart`, `w:commentRangeEnd`
- `lib/document-to-html.js` - Emits `[[DOCX_*:...]]` tokens
- `lib/documents.js` - Document model with `inserted`, `deleted`, `commentRangeStart` types

**Does NOT support export** - only import.

### html-to-docx

**Purpose:** Convert HTML to DOCX format for export.

**Current limitations:**
- No `<w:ins>` / `<w:del>` generation (tracked changes)
- No `comments.xml` generation (Word comments)
- Basic HTML → Word conversion only

**Future enhancement needed:** Add tracked changes and comments support for round-trip fidelity.

### docxjs (docx-preview)

**Purpose:** Render DOCX files for preview in browser.

**Key options:**
```typescript
{
  renderChanges: false,  // Can render tracked changes
  renderComments: false, // Can render comments
  breakPages: true,
  // ...
}
```

**Does NOT modify files** - read-only preview.

### Package Interaction

```
IMPORT:  .docx ──mammoth.js──► HTML+tokens ──Plate──► Editor
EXPORT:  Editor ──serialize──► HTML ──html-to-docx──► .docx
PREVIEW: .docx ──docxjs──► DOM (read-only)
```

**No conflicts:** Each package has a distinct role. Modifications to one don't affect others.

## Key Files

### Import Pipeline
- `packages/mammoth.js/lib/docx/body-reader.js` - Parses DOCX XML elements
- `packages/mammoth.js/lib/document-to-html.js` - Emits tokens for tracked changes/comments
- `src/components/editor/ui/import-toolbar-button.tsx` - Parses tokens, creates suggestions/comments
- `src/components/editor/utils/searchRanges.ts` - Finds token boundaries in editor content

### Export Pipeline
- `src/registry/components/editor/plugins/docx-export-kit.tsx` - DOCX blob generation
- `src/components/editor/ui/docx-export-toolbar-button.tsx` - Export button UI
- `src/components/editor/ui/export-toolbar-button-fixed.tsx` - Multi-format export

### Plate Plugins
- `src/components/editor/plugins/suggestion-kit-app.tsx` - Suggestion system
- `src/components/editor/plugins/comment-kit-app.tsx` - Comment/discussion system

### Logging
- `src/lib/logger.ts` - Unified Logfire logger (prod: Logfire only, dev: Logfire + console)

## Implementation Rules

### Rule 1: Always Handle Orphan Tokens
```typescript
if (!startTokenRange || !endTokenRange) {
  // MUST clean up orphan tokens
  if (startTokenRange) editor.tf.delete({ at: startTokenRange });
  if (endTokenRange) editor.tf.delete({ at: endTokenRange });
  continue; // But don't fail the whole import
}
```

### Rule 2: Never Require User Lookup
```typescript
// CORRECT - Use author name directly
const userId = authorName ?? "imported-unknown";

// WRONG - Don't do this
const user = await findUserByEmail(authorEmail);
const userId = user?.id; // ❌ Will fail for external authors
```

### Rule 3: Always Use rangeRef for Node Operations
```typescript
// Ranges can become stale after node-splitting operations
const startTokenRef = editor.api.rangeRef(startTokenRange);
const endTokenRef = editor.api.rangeRef(endTokenRange);

// After operations, get current ranges
const currentStart = startTokenRef.current;
const currentEnd = endTokenRef.current;

// Always unref when done
startTokenRef.unref();
endTokenRef.unref();
```

### Rule 4: Check for Null Comments in mammoth.js
```javascript
var comment = comments[reference.commentId];
if (!comment) {
  messages.push(results.warning("Comment not found: " + reference.commentId));
  comment = { commentId: reference.commentId, body: [], authorInitials: "" };
}
```

### Rule 5: Always Log with Logfire, Never Crash

Use `src/lib/logger.ts` which wraps Logfire with environment-aware console output.

```typescript
import { logger } from "@/lib/logger";

// For warnings (e.g., skipped items, fallbacks used)
// Uses logfire.warning() under the hood
logger.warning("[DOCX Import] Failed to parse token", {
  rawPayload,
  error: e,
});

// For errors (e.g., failed operations)
// Uses logfire.error() under the hood
logger.error("[DOCX Import] Failed to create comment", e, {
  commentId: comment.id,
  documentId,
});

// For info (e.g., successful operations)
// Uses logfire.info() under the hood
logger.info("[DOCX Import] Import completed", {
  commentsCreated,
  insertions,
  deletions,
});
```

**Logfire API Reference:**

| Logger Method | Logfire Method | Use Case |
|---------------|----------------|----------|
| `logger.warning()` | `logfire.warning()` | Recoverable issues, fallbacks used |
| `logger.error()` | `logfire.error()` | Failed operations, exceptions |
| `logger.info()` | `logfire.info()` | Success messages, metrics |

**Logging behavior:**
- **Production**: Logs to Logfire only (no console spam)
- **Development**: Logs to both Logfire AND console (for debugging)

## Plate Mark Structures

### Suggestion Marks
```typescript
{
  [KEYS.suggestion]: true,
  [getSuggestionKey(id)]: {
    id: string,
    type: "insert" | "remove",
    userId: string,
    createdAt: number
  }
}
```

### Comment Marks
```typescript
{
  [KEYS.comment]: true,
  [getCommentKey(discussionId)]: true,
  [getTransientCommentKey()]: true // During creation
}
```

## Common Debugging Scenarios

### Tokens Not Being Parsed
1. Check mammoth.js output in browser console
2. Verify token prefixes match exactly between files
3. Check that `cleanDocx()` isn't stripping tokens

### Suggestions Not Appearing
1. Verify `KEYS.suggestion` is set to `true`
2. Check `getSuggestionKey(id)` contains full object, not just ID
3. Ensure `type` is exactly `"insert"` or `"remove"`

### Comments Not Saved
1. Check `createDiscussionWithComment` API call
2. Verify `documentId` is passed correctly
3. Check TRPC mutation response for errors

### Ranges Becoming Stale
1. Use `rangeRef` before any node-modifying operations
2. Call `unref()` after operations complete
3. Re-fetch ranges after `setNodes` with `split: true`

## Testing Checklist

When modifying DOCX import/export:

- [ ] Test with Word document containing only insertions
- [ ] Test with Word document containing only deletions
- [ ] Test with Word document containing mixed tracked changes
- [ ] Test with Word document containing single comment
- [ ] Test with Word document containing multiple comments
- [ ] Test with Word document containing both tracked changes AND comments
- [ ] Test with document from different sources (Word, LibreOffice, Google Docs)
- [ ] Test round-trip: Import → Make changes → Export → Import again
- [ ] Verify no tokens are visible in final editor content
- [ ] Verify all authors are attributed correctly

## Detailed References

- **Import implementation**: See [references/import-pipeline.md](references/import-pipeline.md)
- **Export implementation**: See [references/export-pipeline.md](references/export-pipeline.md)
- **mammoth.js modifications**: See [references/mammoth-modifications.md](references/mammoth-modifications.md)
- **Packages overview**: See [references/packages-overview.md](references/packages-overview.md)

## Emergency Fixes

### If tokens appear in editor content:
```typescript
// Force cleanup of all remaining tokens
const tokenPatterns = [
  /\[\[DOCX_INS_START:.*?\]\]/g,
  /\[\[DOCX_INS_END:.*?\]\]/g,
  /\[\[DOCX_DEL_START:.*?\]\]/g,
  /\[\[DOCX_DEL_END:.*?\]\]/g,
  /\[\[DOCX_CMT_START:.*?\]\]/g,
  /\[\[DOCX_CMT_END:.*?\]\]/g,
];
// Search and delete each match
```

### If suggestions aren't displaying:
1. Check suggestion plugin is configured correctly
2. Verify `SuggestionLeaf` is rendering
3. Check browser console for rendering errors
