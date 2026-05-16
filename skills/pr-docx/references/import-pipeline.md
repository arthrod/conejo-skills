# DOCX Import Pipeline - Deep Dive

## Overview

The import pipeline converts DOCX files into Plate editor content while preserving tracked changes as suggestions and comments as discussions.

## Critical Understanding: Token → Plate Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           TOKEN LIFECYCLE                                    │
└─────────────────────────────────────────────────────────────────────────────┘

1. DOCX FILE (XML)
   └─► <w:commentRangeStart w:id="0"/>Hello world<w:commentRangeEnd w:id="0"/>

2. MAMMOTH.JS (document-to-html.js)
   └─► findHtmlPath().wrap() ensures token is INLINE
   └─► Output: <p>[[DOCX_CMT_START:{...}]]Hello world[[DOCX_CMT_END:0]]</p>

3. PLATE DESERIALIZER (html.deserialize)
   └─► Creates nodes: [{ type: "p", children: [{ text: "[[TOKEN]]Hello..." }] }]

4. SEARCHRANGE (searchRanges.ts)
   └─► Searches text content for token strings
   └─► Returns Range: { anchor: {path, offset}, focus: {path, offset} }

5. APPLY MARKS (setNodes)
   └─► Applies suggestion/comment marks to range BETWEEN tokens
   └─► Deletes token text

6. FINAL STATE
   └─► Clean text with invisible marks: [{ text: "Hello world", [commentKey]: true }]
```

**Why Token Positioning Matters:**

| Token Position | searchRange Result | Import Result |
|----------------|-------------------|---------------|
| Inline with text | Found | Success |
| Outside paragraph | May be lost | Failure |
| Different node | Wrong range | Corrupted |

## Step 1: File Selection

**Component:** `ImportToolbarButton`
**File:** `src/components/editor/ui/import-toolbar-button.tsx`

```typescript
const { openFilePicker } = useFilePicker({
  accept: [".docx", ".html", ".htm", ".txt", ".md", ".mdx"],
  multiple: false,
  onFilesSelected: async (data) => {
    const file = data?.plainFiles?.[0];
    const extension = getFileExtension(file.name);

    switch (extension) {
      case ".docx":
        await handleDocxFile(file);
        break;
      // ... other formats
    }
  },
});
```

## Step 2: mammoth.js Conversion

**Files:**
- `packages/mammoth.js/lib/docx/body-reader.js` - XML parsing
- `packages/mammoth.js/lib/document-to-html.js` - HTML generation

### body-reader.js - DOCX XML Parsing

Handles these Word XML elements:

```javascript
// Tracked change: Insertion
"w:ins": function (element) {
  var author = element.attributes["w:author"];
  var date = element.attributes["w:date"];
  return readXmlElements(element.children).map(function (children) {
    return documents.inserted(children, { author: author, date: date });
  });
},

// Tracked change: Deletion
"w:del": function (element) {
  var author = element.attributes["w:author"];
  var date = element.attributes["w:date"];
  return readXmlElements(element.children).map(function (children) {
    return documents.deleted(children, { author: author, date: date });
  });
},

// Deleted text (inside w:del)
"w:delText": function (element) {
  return elementResult(new documents.Text(element.text()));
},

// Comment range start
"w:commentRangeStart": function (element) {
  return elementResult(
    documents.commentRangeStart({ commentId: element.attributes["w:id"] })
  );
},

// Comment range end
"w:commentRangeEnd": function (element) {
  return elementResult(
    documents.commentRangeEnd({ commentId: element.attributes["w:id"] })
  );
},
```

### document-to-html.js - Token Emission

Converts document elements to HTML with embedded tokens:

```javascript
// Token prefixes - MUST match import-toolbar-button.tsx
var DOCX_INSERTION_START_TOKEN_PREFIX = "[[DOCX_INS_START:";
var DOCX_INSERTION_END_TOKEN_PREFIX = "[[DOCX_INS_END:";
var DOCX_INSERTION_TOKEN_SUFFIX = "]]";
// ... similar for deletions and comments

// Insertion handler
inserted: function (element, messages, options) {
  var children = convertElements(element.children, messages, options);
  var changeId = "ins-" + trackedChangeIdCounter++;
  var payload = encodeTrackedChangePayload({
    id: changeId,
    author: element.author,
    date: element.date,
  });
  var startToken = DOCX_INSERTION_START_TOKEN_PREFIX + payload + DOCX_INSERTION_TOKEN_SUFFIX;
  var endToken = DOCX_INSERTION_END_TOKEN_PREFIX + encodeURIComponent(changeId) + DOCX_INSERTION_TOKEN_SUFFIX;
  return [Html.text(startToken)].concat(children).concat([Html.text(endToken)]);
},

// Comment range start handler
commentRangeStart: function (element, messages, options) {
  var comment = comments[element.commentId];
  var payload = { id: element.commentId };
  if (comment) {
    payload.authorName = comment.authorName;
    payload.authorInitials = comment.authorInitials;
    payload.date = comment.date;
    if (comment.body && comment.body.length > 0) {
      payload.text = extractTextFromElements(comment.body);
    }
  }
  var token = DOCX_COMMENT_START_TOKEN_PREFIX +
    encodeURIComponent(JSON.stringify(payload)) +
    DOCX_COMMENT_TOKEN_SUFFIX;
  return [Html.text(token)];
},
```

## Step 3: HTML Deserialization

**File:** `src/components/editor/ui/import-toolbar-button.tsx`

```typescript
const getFileNodes = (text: string, type: ImportType) => {
  if (type === "markdown") {
    return editor.getApi(MarkdownPlugin).markdown.deserialize(text);
  }

  const html = type === "docx" ? cleanDocx(text, "") : text;
  const element = parseHtmlElement(html);

  if (!element) return [];

  return editor.api.html.deserialize({ element });
};
```

## Step 4: Token Parsing

### Tracked Changes

```typescript
const parseDocxTrackedChangeTokens = (html: string): DocxTrackedChange[] => {
  const changes: DocxTrackedChange[] = [];

  // Parse insertions
  const insertionPattern = new RegExp(
    `${escapeRegExp(DOCX_INSERTION_START_TOKEN_PREFIX)}(.*?)${escapeRegExp(
      DOCX_INSERTION_TOKEN_SUFFIX
    )}`,
    "g"
  );

  for (const match of html.matchAll(insertionPattern)) {
    const rawPayload = match[1];
    const payload = JSON.parse(decodeURIComponent(rawPayload));
    changes.push({
      id: payload.id,
      author: payload.author,
      date: payload.date,
      type: "insert",
      startToken: `${DOCX_INSERTION_START_TOKEN_PREFIX}${rawPayload}${DOCX_INSERTION_TOKEN_SUFFIX}`,
      endToken: `${DOCX_INSERTION_END_TOKEN_PREFIX}${encodeURIComponent(payload.id)}${DOCX_INSERTION_TOKEN_SUFFIX}`,
    });
  }
  // Similar for deletions...
  return changes;
};
```

### Comments

```typescript
const parseDocxCommentTokens = (html: string): DocxComment[] => {
  const comments: DocxComment[] = [];

  const startPattern = new RegExp(
    `${escapeRegExp(DOCX_COMMENT_START_TOKEN_PREFIX)}(.*?)${escapeRegExp(
      DOCX_COMMENT_TOKEN_SUFFIX
    )}`,
    "g"
  );

  for (const match of html.matchAll(startPattern)) {
    const rawPayload = match[1];
    const payload = JSON.parse(decodeURIComponent(rawPayload));
    comments.push({
      id: payload.id,
      authorName: payload.authorName,
      authorInitials: payload.authorInitials,
      date: payload.date,
      text: payload.text,
      startToken: `${DOCX_COMMENT_START_TOKEN_PREFIX}${rawPayload}${DOCX_COMMENT_TOKEN_SUFFIX}`,
      endToken: `${DOCX_COMMENT_END_TOKEN_PREFIX}${encodeURIComponent(payload.id)}${DOCX_COMMENT_TOKEN_SUFFIX}`,
    });
  }
  return comments;
};
```

## Step 5: Applying Suggestions

```typescript
const applyTrackedChangeSuggestions = (
  editor: ReturnType<typeof useEditorRef>,
  changes: DocxTrackedChange[]
): number => {
  let appliedCount = 0;

  for (const change of changes) {
    const startTokenRange = searchRange(editor, change.startToken);
    const endTokenRange = searchRange(editor, change.endToken);

    // Handle orphan tokens
    if (!startTokenRange || !endTokenRange) {
      if (startTokenRange) editor.tf.delete({ at: startTokenRange });
      if (endTokenRange) editor.tf.delete({ at: endTokenRange });
      continue;
    }

    // Use rangeRef for stability
    const startTokenRef = editor.api.rangeRef(startTokenRange);
    const endTokenRef = editor.api.rangeRef(endTokenRange);

    const changeRange = {
      anchor: startTokenRef.current!.focus,
      focus: endTokenRef.current!.anchor,
    };

    // Apply suggestion marks
    editor.tf.setNodes(
      {
        [KEYS.suggestion]: true,
        [getSuggestionKey(change.id)]: {
          id: change.id,
          type: change.type,
          userId: formatAuthorAsUserId(change.author),
          createdAt: parsedDate,
        },
      },
      { at: changeRange, match: TextApi.isText, split: true }
    );

    appliedCount++;

    // Clean up tokens (end first, then start to preserve positions)
    const endRange = endTokenRef.unref();
    if (endRange) editor.tf.delete({ at: endRange });

    const startRange = startTokenRef.unref();
    if (startRange) editor.tf.delete({ at: startRange });
  }

  return appliedCount;
};
```

## Step 6: Creating Comments

### The Golden Rule: Preserve Comments with ANY Location Marker

```
┌───────────────────┬───────────────────────────────┐
│     Scenario      │            Action             │
├───────────────────┼───────────────────────────────┤
│ Has start, no end │ end = start → point comment ✓ │
├───────────────────┼───────────────────────────────┤
│ Has end, no start │ start = end → point comment ✓ │
├───────────────────┼───────────────────────────────┤
│ Has neither       │ Skip (only valid skip)        │
└───────────────────┴───────────────────────────────┘
```

```typescript
for (const comment of docxComments) {
  const startTokenRange = searchRange(editor, comment.startToken);
  const endTokenRange = searchRange(editor, comment.endToken);

  // Golden rule: if we have ANY location marker, preserve the comment
  if (!startTokenRange && !endTokenRange) {
    if (process.env.NODE_ENV !== "production") {
      console.warn("[DOCX Import] Skipping comment with no location markers:", comment.id);
    }
    continue;
  }

  // Use whichever marker we have, fallback to the other for point comments
  const effectiveStartTokenRange = startTokenRange ?? endTokenRange;
  const effectiveEndTokenRange = endTokenRange ?? startTokenRange;

  // Use rangeRef with effective ranges
  const startTokenRef = editor.api.rangeRef(effectiveStartTokenRange!);
  const endTokenRef = editor.api.rangeRef(effectiveEndTokenRange!);

  const commentRange = {
    anchor: startTokenRef.current!.focus,
    focus: endTokenRef.current!.anchor,
  };

  // Get highlighted text
  let documentContent = editor.api.string(commentRange);
  if (!documentContent?.trim()) {
    documentContent = "Imported comment";
  }

  // Build comment content
  const contentRich = comment.text
    ? [{ children: [{ text: comment.text }], type: "p" }]
    : undefined;

  try {
    // Create discussion in database
    const discussion = await createDiscussionWithComment.mutateAsync({
      contentRich,
      documentContent,
      documentId,
    });

    commentsCreated++;

    // Apply comment marks
    editor.tf.withMerging(() => {
      editor.tf.setNodes(
        {
          [getCommentKey(discussion.id)]: true,
          [getTransientCommentKey()]: true,
          [KEYS.comment]: true,
        },
        { at: markRange, match: TextApi.isText, split: true }
      );
      editor.setOption(commentPlugin, "updateTimestamp", Date.now());
    });
  } catch (e) {
    if (process.env.NODE_ENV !== "production") {
      console.warn("Failed to create comment:", comment.id, e);
    }
  }

  // Clean up tokens (only delete tokens that actually existed)
  // For point comments, both refs may point to the same range
  const endRange = endTokenRef.unref();
  const startRange = startTokenRef.unref();

  // Delete end token only if it existed as a separate token
  if (endTokenRange && endRange) {
    editor.tf.delete({ at: endRange });
  }
  // Delete start token only if it existed as a separate token
  if (startTokenRange && startRange) {
    editor.tf.delete({ at: startRange });
  }
}
```

## Range Search Utility

**File:** `src/components/editor/utils/searchRanges.ts`

The `searchRange` function finds text in the editor and returns its range:

```typescript
export function searchRange(
  editor: ReturnType<typeof useEditorRef>,
  searchText: string
): Range | null {
  // Normalizes text and searches through all text nodes
  // Returns the Range of the first match
  // Used to locate token boundaries
}
```

## Error Handling Summary

All errors are logged to Logfire (production + development) and console (development only).

| Scenario | Handling |
|----------|----------|
| Orphan start token | Delete token, continue |
| Orphan end token | Delete token, continue |
| Missing comment | `logger.warning()`, continue |
| API failure | `logger.error()`, continue |
| Invalid payload | `logger.warning()`, skip |
| Empty comment range | Use placeholder text |
| setNodes failure | `logger.error()`, continue |

**Logging utility:** `src/lib/logger.ts`

```typescript
import { logger } from "@/lib/logger";

// Warnings for recoverable issues (uses logfire.warning())
logger.warning("[DOCX Import] Failed to parse token", { rawPayload, error });

// Errors for failed operations (uses logfire.error())
logger.error("[DOCX Import] Failed to create comment", error, {
  commentId,
  documentId,
});
```

**Logfire API mapping:**
| Logger | Logfire | Use Case |
|--------|---------|----------|
| `logger.warning()` | `logfire.warning()` | Recoverable issues |
| `logger.error()` | `logfire.error()` | Failed operations |
| `logger.info()` | `logfire.info()` | Success/metrics |
