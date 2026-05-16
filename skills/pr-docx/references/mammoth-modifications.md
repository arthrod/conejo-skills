# mammoth.js Modifications - Deep Dive

## Overview

We maintain a forked version of mammoth.js at `packages/mammoth.js/` with custom modifications for tracked changes and comments support.

## Modified Files

### 1. lib/document-to-html.js

**Purpose:** Convert document elements to HTML with embedded tokens.

#### Token Constants (lines 13-24)

```javascript
// Token prefixes for tracked changes - parsed by import-toolbar-button.tsx
var DOCX_INSERTION_START_TOKEN_PREFIX = "[[DOCX_INS_START:";
var DOCX_INSERTION_END_TOKEN_PREFIX = "[[DOCX_INS_END:";
var DOCX_INSERTION_TOKEN_SUFFIX = "]]";
var DOCX_DELETION_START_TOKEN_PREFIX = "[[DOCX_DEL_START:";
var DOCX_DELETION_END_TOKEN_PREFIX = "[[DOCX_DEL_END:";
var DOCX_DELETION_TOKEN_SUFFIX = "]]";

// Token prefixes for comment ranges - parsed by import-toolbar-button.tsx
var DOCX_COMMENT_START_TOKEN_PREFIX = "[[DOCX_CMT_START:";
var DOCX_COMMENT_END_TOKEN_PREFIX = "[[DOCX_CMT_END:";
var DOCX_COMMENT_TOKEN_SUFFIX = "]]";
```

**CRITICAL:** These constants MUST match exactly with `import-toolbar-button.tsx`

#### ID Counter (inside DocumentConversion)

```javascript
function DocumentConversion(options, comments) {
  var noteNumber = 1;
  // Counter for generating unique IDs for tracked changes without explicit IDs
  var trackedChangeIdCounter = 1;  // Scoped per conversion, not global
  // ...
}
```

**Why scoped?** Prevents ID collisions in concurrent/sequential conversions.

#### Tracked Change Payload Encoder

```javascript
function encodeTrackedChangePayload(payload) {
  return encodeURIComponent(JSON.stringify(payload));
}
```

#### Insertion Handler (elementConverters.inserted)

```javascript
inserted: function (element, messages, options) {
  var children = convertElements(element.children, messages, options);
  // Generate a unique ID for this tracked change
  var changeId = "ins-" + trackedChangeIdCounter++;
  var payload = encodeTrackedChangePayload({
    id: changeId,
    author: element.author,
    date: element.date,
  });
  var startToken =
    DOCX_INSERTION_START_TOKEN_PREFIX +
    payload +
    DOCX_INSERTION_TOKEN_SUFFIX;
  var endToken =
    DOCX_INSERTION_END_TOKEN_PREFIX +
    encodeURIComponent(changeId) +
    DOCX_INSERTION_TOKEN_SUFFIX;
  return [Html.text(startToken)]
    .concat(children)
    .concat([Html.text(endToken)]);
},
```

#### Deletion Handler (elementConverters.deleted)

```javascript
deleted: function (element, messages, options) {
  var children = convertElements(element.children, messages, options);
  var changeId = "del-" + trackedChangeIdCounter++;
  var payload = encodeTrackedChangePayload({
    id: changeId,
    author: element.author,
    date: element.date,
  });
  var startToken =
    DOCX_DELETION_START_TOKEN_PREFIX +
    payload +
    DOCX_DELETION_TOKEN_SUFFIX;
  var endToken =
    DOCX_DELETION_END_TOKEN_PREFIX +
    encodeURIComponent(changeId) +
    DOCX_DELETION_TOKEN_SUFFIX;
  return [Html.text(startToken)]
    .concat(children)
    .concat([Html.text(endToken)]);
},
```

#### Comment Range Start Handler

**CRITICAL: Must use `findHtmlPath().wrap()` for correct token positioning!**

```javascript
commentRangeStart: function (element, messages, options) {
  return findHtmlPath(element, htmlPaths.empty).wrap(function () {
    var comment = comments[element.commentId];
    var payload = { id: element.commentId };
    if (!comment) {
      messages.push(
        results.warning(
          "Comment with ID " + element.commentId +
          " was referenced by a range but not found in the document"
        )
      );
    }
    if (comment) {
      payload.authorName = comment.authorName;
      payload.authorInitials = comment.authorInitials;
      payload.date = comment.date;
      if (comment.body && comment.body.length > 0) {
        payload.text = extractTextFromElements(comment.body);
      }
    }
    var token =
      DOCX_COMMENT_START_TOKEN_PREFIX +
      encodeURIComponent(JSON.stringify(payload)) +
      DOCX_COMMENT_TOKEN_SUFFIX;
    return [Html.text(token)];
  });
},
```

**Why `findHtmlPath().wrap()` is required:**

Without wrap, tokens may appear outside their containing paragraph in the HTML output:
```html
<!-- BAD: Token outside paragraph -->
<p>Hello</p>[[DOCX_CMT_START:...]]<p>world</p>

<!-- GOOD: Token inline with content -->
<p>Hello[[DOCX_CMT_START:...]]world</p>
```

The `wrap()` function:
1. **`findHtmlPath(element, htmlPaths.empty)`** - Finds where this element belongs in the HTML hierarchy
2. **`htmlPaths.empty`** - No HTML wrapper (just the token text, no `<span>`)
3. **`.wrap(fn)`** - Ensures the callback's output is positioned correctly in the document flow

This is critical because `searchRange()` in Plate searches TEXT CONTENT of nodes. If the token is in a separate node or lost during deserialization, the comment range cannot be found.

#### Comment Range End Handler

```javascript
commentRangeEnd: function (element, messages, options) {
  return findHtmlPath(element, htmlPaths.empty).wrap(function () {
    var token =
      DOCX_COMMENT_END_TOKEN_PREFIX +
      encodeURIComponent(element.commentId) +
      DOCX_COMMENT_TOKEN_SUFFIX;
    return [Html.text(token)];
  });
},
```

#### Text Extraction Helper

```javascript
function extractTextFromElements(elements) {
  var text = "";
  function extractFromElement(element) {
    if (element.type === documents.types.text) {
      text += element.value;
    } else if (element.children) {
      element.children.forEach(extractFromElement);
    }
  }
  elements.forEach(extractFromElement);
  return text;
}
```

#### Null Comment Guard (convertCommentReference)

```javascript
function convertCommentReference(reference, messages, options) {
  return findHtmlPath(reference, htmlPaths.ignore).wrap(function () {
    var comment = comments[reference.commentId];
    if (!comment) {
      messages.push(
        results.warning(
          "Comment with ID " +
            reference.commentId +
            " was referenced but not found in the document"
        )
      );
      // Create a placeholder comment to allow conversion to continue
      comment = { commentId: reference.commentId, body: [], authorInitials: "" };
    }
    // ... rest of function
  });
}
```

### 2. lib/docx/body-reader.js

**Purpose:** Parse DOCX XML elements into document model.

#### Tracked Change Handlers

```javascript
// Tracked changes: wrap content in documents.inserted with author/date metadata
"w:ins": function (element) {
  var author = element.attributes["w:author"];
  var date = element.attributes["w:date"];
  return readXmlElements(element.children).map(function (children) {
    return documents.inserted(children, {
      author: author,
      date: date,
    });
  });
},

// Tracked deletions: wrap content in documents.deleted with author/date metadata
"w:del": function (element) {
  var author = element.attributes["w:author"];
  var date = element.attributes["w:date"];
  return readXmlElements(element.children).map(function (children) {
    return documents.deleted(children, {
      author: author,
      date: date,
    });
  });
},

// Handle deleted text within w:del elements
"w:delText": function (element) {
  return elementResult(new documents.Text(element.text()));
},
```

#### Comment Range Handlers

```javascript
"w:commentRangeStart": function (element) {
  return elementResult(
    documents.commentRangeStart({
      commentId: element.attributes["w:id"],
    })
  );
},

"w:commentRangeEnd": function (element) {
  return elementResult(
    documents.commentRangeEnd({
      commentId: element.attributes["w:id"],
    })
  );
},
```

#### Removed from ignoreElements

```javascript
var ignoreElements = {
  // ...
  // w:del and w:ins are now handled by xmlElementReaders for tracked changes support
  // (removed: "w:del": true)
  // ...
};
```

### 3. lib/documents.js

**Purpose:** Document model definitions.

#### Document Types

```javascript
var types = (exports.types = {
  // ...
  commentReference: "commentReference",
  comment: "comment",
  commentRangeStart: "commentRangeStart",
  commentRangeEnd: "commentRangeEnd",
  inserted: "inserted",
  deleted: "deleted",
  // ...
});
```

#### Factory Functions

```javascript
function inserted(children, options) {
  options = options || {};
  return {
    type: types.inserted,
    children: children,
    author: options.author || null,
    date: options.date || null,
  };
}

function deleted(children, options) {
  options = options || {};
  return {
    type: types.deleted,
    children: children,
    author: options.author || null,
    date: options.date || null,
  };
}

function commentRangeStart(options) {
  return {
    type: types.commentRangeStart,
    commentId: options.commentId,
  };
}

function commentRangeEnd(options) {
  return {
    type: types.commentRangeEnd,
    commentId: options.commentId,
  };
}

function comment(options) {
  return {
    type: types.comment,
    commentId: options.commentId,
    body: options.body,
    authorName: options.authorName || null,
    authorInitials: options.authorInitials || null,
    date: options.date || null,
  };
}
```

### 4. lib/docx/comments-reader.js

**Purpose:** Parse comments.xml from DOCX.

```javascript
function createCommentsReader(bodyReader) {
  function readCommentsXml(element) {
    return Result.combine(
      element.getElementsByTagName("w:comment").map(readCommentElement)
    );
  }

  function readCommentElement(element) {
    var id = element.attributes["w:id"];

    function readOptionalAttribute(name) {
      return (element.attributes[name] || "").trim() || null;
    }

    return bodyReader.readXmlElements(element.children).map(function (body) {
      return documents.comment({
        commentId: id,
        body: body,
        authorName: readOptionalAttribute("w:author"),
        authorInitials: readOptionalAttribute("w:initials"),
      });
    });
  }

  return readCommentsXml;
}
```

## Testing

**File:** `packages/mammoth.js/test/mammoth.tests.js`

Key test updated for token format:

```javascript
test("when style mapping is defined for comment references then comments are included", function () {
  var docxPath = path.join(__dirname, "test-data/comments.docx");
  var options = {
    idPrefix: "doc-42-",
    styleMap: "comment-reference => sup",
  };
  return mammoth
    .convertToHtml({ path: docxPath }, options)
    .then(function (result) {
      // Comment tokens are emitted for import-toolbar-button.tsx to parse
      var comment0Token = "[[DOCX_CMT_START:" + encodeURIComponent(JSON.stringify({
        id: "0",
        authorName: "Michael Williamson",
        authorInitials: "MW",
        date: null,
        text: "A tachyon walks into a bar."
      })) + "]]";
      var expectedOutput =
        "<p>" + comment0Token + "Ouch" + "[[DOCX_CMT_END:0]]" +
        '<sup><a href="#doc-42-comment-0"...' +
        // ...
    });
});
```

## Debugging mammoth.js

### Viewing Raw Output

```javascript
// In browser console or test
const result = await mammoth.convertToHtml({ arrayBuffer });
console.log(result.value); // Shows HTML with tokens
console.log(result.messages); // Shows warnings
```

### Common Issues

1. **Tokens not appearing**: Check body-reader.js handlers are registered
2. **Missing author**: Verify `w:author` attribute exists in DOCX XML
3. **Comments empty**: Check comments.xml is being read correctly
4. **Warnings about missing comments**: Comment ID mismatch between range and reference

### ESLint Configuration

mammoth.js uses strict ESLint rules:
- 4 spaces for indentation (not tabs)
- No trailing commas
- No space before function parentheses

Run tests without eslint:
```bash
cd packages/mammoth.js
npx mocha 'test/**/*.tests.js'
```
