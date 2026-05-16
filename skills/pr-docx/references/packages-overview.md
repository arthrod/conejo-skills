# DOCX Packages Overview

## Package Roles

The codebase uses multiple packages for DOCX handling. Each has a distinct role:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PACKAGE RESPONSIBILITIES                           │
└─────────────────────────────────────────────────────────────────────────────┘

IMPORT:   .docx ──► mammoth.js ──► HTML+tokens ──► Plate deserializer ──► Editor
EXPORT:   Editor ──► serialize ──► HTML ──► html-to-docx ──► .docx
PREVIEW:  .docx ──► docxjs ──► DOM (read-only)
UTILS:    @platejs/docx ──► cleanDocx(), DOCX utilities
```

## mammoth.js (Custom Fork)

**Location:** `packages/mammoth.js/`
**Direction:** Import only (DOCX → HTML)
**Version:** 1.11.0 (forked)

### Purpose

Convert DOCX files to HTML with embedded tokens for tracked changes and comments that Plate can parse.

### Key Modifications

| File | Modification |
|------|--------------|
| `lib/docx/body-reader.js` | Added `w:ins`, `w:del`, `w:commentRangeStart`, `w:commentRangeEnd` handlers |
| `lib/document-to-html.js` | Emits `[[DOCX_*:...]]` tokens with `findHtmlPath().wrap()` |
| `lib/documents.js` | Added `inserted`, `deleted`, `commentRangeStart`, `commentRangeEnd` types |
| `lib/docx/comments-reader.js` | Parses `comments.xml` for comment metadata |

### Token Format

```javascript
// Tracked change (insertion)
"[[DOCX_INS_START:" + encodeURIComponent(JSON.stringify({
  id: "ins-1",
  author: "John Doe",
  date: "2024-01-15T10:30:00Z"
})) + "]]"

// Comment range
"[[DOCX_CMT_START:" + encodeURIComponent(JSON.stringify({
  id: "0",
  authorName: "Jane Smith",
  authorInitials: "JS",
  date: "2024-01-15T10:30:00Z",
  text: "Please review this section"
})) + "]]"
```

### Critical: Token Positioning

All token-emitting handlers MUST use `findHtmlPath(element, htmlPaths.empty).wrap()`:

```javascript
// ✅ CORRECT
commentRangeStart: function (element, messages, options) {
  return findHtmlPath(element, htmlPaths.empty).wrap(function () {
    // ... build token ...
    return [Html.text(token)];
  });
},

// ❌ WRONG - tokens may appear outside paragraphs
commentRangeStart: function (element, messages, options) {
  return [Html.text(token)];  // No wrap!
},
```

### No Export Support

mammoth.js only handles DOCX → HTML. It cannot generate DOCX files.

---

## html-to-docx

**Location:** `plugin/docx-export/packages/html-to-docx/`
**Direction:** Export only (HTML → DOCX)
**Version:** 1.8.0

### Purpose

Convert HTML content to DOCX format for export from Plate editor.

### Key Files

| File | Purpose |
|------|---------|
| `src/html-to-docx.js` | Main conversion entry point |
| `src/docx-document.js` | DOCX document generation |
| `src/helpers/render-document-file.js` | Document file rendering |
| `src/helpers/xml-builder.js` | XML structure building |

### Usage

```typescript
import HTMLtoDOCX from "./packages/html-to-docx/index.js";

const blob = await HTMLtoDOCX(htmlString, null, {
  orientation: "portrait",
  margins: { top: 720, right: 720, bottom: 720, left: 720 },
  // ...
}, null);
```

### Current Limitations

| Feature | Status |
|---------|--------|
| Basic HTML conversion | Supported |
| Images | Supported |
| Tables | Supported |
| Headers/Footers | Supported |
| Tracked changes (`<w:ins>`, `<w:del>`) | NOT SUPPORTED |
| Comments (`comments.xml`) | NOT SUPPORTED |

### Future Enhancement Needed

For round-trip fidelity, html-to-docx needs:
1. `<ins>` / `<del>` → `<w:ins>` / `<w:del>` conversion
2. Comment marks → `comments.xml` generation
3. Author/date preservation in Word format

### No Import Support

html-to-docx only handles HTML → DOCX. It cannot read DOCX files.

---

## docxjs (docx-preview)

**Location:** `packages/docxjs/`
**Direction:** Preview only (read-only)

### Purpose

Render DOCX files for preview in the browser without modification.

### Key Files

| File | Purpose |
|------|---------|
| `src/docx-preview.ts` | Main preview API |
| `src/document-parser.ts` | DOCX parsing |
| `src/html-renderer.ts` | DOM rendering |
| `src/word-document.ts` | Document model |

### Usage

```typescript
import { renderAsync, Options } from "./docx-preview";

const options: Partial<Options> = {
  renderChanges: true,   // Show tracked changes
  renderComments: true,  // Show comments
  breakPages: true,
  className: "docx",
};

await renderAsync(docxBlob, container, styleContainer, options);
```

### Key Options

```typescript
interface Options {
  renderChanges: boolean;    // Render tracked changes (default: false)
  renderComments: boolean;   // Render comments (default: false)
  breakPages: boolean;       // Page breaks (default: true)
  renderHeaders: boolean;    // Headers (default: true)
  renderFooters: boolean;    // Footers (default: true)
  renderFootnotes: boolean;  // Footnotes (default: true)
  // ...
}
```

### No Modification Support

docxjs is read-only. It cannot modify or create DOCX files.

---

## @platejs/docx

**Location:** `node_modules/@platejs/docx/`
**Direction:** Utilities for both import/export

### Purpose

Plate.js DOCX utilities, primarily the `cleanDocx()` function.

### Key Function

```typescript
import { cleanDocx } from "@platejs/docx";

// Clean mammoth.js HTML output for Plate deserialization
const html = cleanDocx(mammothHtml, "");
```

### What cleanDocx Does

1. Normalizes HTML structure for Plate
2. Removes Word-specific artifacts
3. Preserves content and structure
4. **Does NOT strip tokens** - our custom tokens are preserved

---

## Package Interaction Summary

```
                    ┌─────────────────┐
                    │   .docx file    │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│  mammoth.js     │ │  docxjs         │ │  (nothing)      │
│  (Import)       │ │  (Preview)      │ │                 │
│                 │ │                 │ │                 │
│  DOCX → HTML    │ │  DOCX → DOM     │ │                 │
│  with tokens    │ │  (read-only)    │ │                 │
└────────┬────────┘ └─────────────────┘ └─────────────────┘
         │
         ▼
┌─────────────────┐
│  @platejs/docx  │
│  cleanDocx()    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Plate Editor   │
│  (with marks)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  html-to-docx   │
│  (Export)       │
│                 │
│  HTML → DOCX    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   .docx file    │
└─────────────────┘
```

## No Conflicts

Each package has a distinct, non-overlapping role:
- **mammoth.js**: Import path only
- **html-to-docx**: Export path only
- **docxjs**: Preview only (read-only)
- **@platejs/docx**: Utilities only

Modifications to one package do not affect others.

## Debugging by Package

| Symptom | Check Package |
|---------|---------------|
| Tokens not parsed | mammoth.js (document-to-html.js) |
| Tokens in wrong position | mammoth.js (missing `wrap()`) |
| cleanDocx strips content | @platejs/docx |
| Export missing content | html-to-docx |
| Preview not showing | docxjs |
| Marks not applied | import-toolbar-button.tsx (Plate) |
