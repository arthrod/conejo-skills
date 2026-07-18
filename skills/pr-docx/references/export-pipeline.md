# DOCX Export Pipeline - Deep Dive

## Current Status

**IMPORT: Fully Implemented**
**EXPORT: Partially Implemented - Needs Enhancement**

The export currently creates valid DOCX files but does NOT yet convert:
- Plate suggestions → Word tracked changes (`<w:ins>`, `<w:del>`)
- Plate comments → Word comments (`<w:comment>`)

## Export Buttons

### Button 1: Multi-Format Export

**Component:** `ExportToolbarButtonFixed`
**File:** `src/components/editor/ui/export-toolbar-button-fixed.tsx`

Features:
- PDF, HTML, Word, Markdown formats
- Page orientation (Portrait/Landscape)
- Page format (A4, Letter, etc.)
- Scale options

### Button 2: DOCX-Specific Export

**Component:** `DocxExportToolbarButton`
**File:** `src/components/editor/ui/docx-export-toolbar-button.tsx`

Features:
- Portrait/Landscape toggle
- Direct DOCX download

## Current Export Implementation

**File:** `src/registry/components/editor/plugins/docx-export-kit.tsx`

```typescript
export interface DocxExportOptions {
  customStyles?: string;
  fontFamily?: string;
  margins?: DocxExportMargins;
  orientation?: "portrait" | "landscape";
  title?: string;
}

export async function exportToDocx(
  value: Value,
  options?: DocxExportOptions
): Promise<Blob> {
  // 1. Serialize Plate content to HTML
  const html = await serializeToWordHtml(value, options);

  // 2. Convert HTML to DOCX blob
  const blob = await htmlToDocxBlob(html, options);

  return blob;
}

export async function exportEditorToDocx(
  value: Value,
  filename: string,
  options?: DocxExportOptions
): Promise<void> {
  const blob = await exportToDocx(value, options);
  downloadBlob(blob, filename);
}
```

## Required Enhancements

### Enhancement 1: Suggestions → Tracked Changes

**Goal:** Convert Plate suggestions to Word's `<w:ins>` and `<w:del>` elements.

```typescript
// PROPOSED: Extract suggestions during serialization
function serializeSuggestionsToWordHtml(node: Node, value: Value): string {
  // Check for suggestion marks
  const suggestionKey = findSuggestionKey(node);
  if (suggestionKey) {
    const suggestion = node[suggestionKey];

    if (suggestion.type === "insert") {
      // Wrap in <ins> with author/date attributes
      return `<ins data-author="${suggestion.userId}" data-date="${new Date(suggestion.createdAt).toISOString()}">${content}</ins>`;
    }

    if (suggestion.type === "remove") {
      // Wrap in <del> with author/date attributes
      return `<del data-author="${suggestion.userId}" data-date="${new Date(suggestion.createdAt).toISOString()}">${content}</del>`;
    }
  }

  return content;
}
```

### Enhancement 2: Comments → Word Comments

**Goal:** Convert Plate discussions to Word's comment system.

Word comment structure:
```xml
<!-- In document.xml -->
<w:commentRangeStart w:id="0"/>
<w:r><w:t>Commented text</w:t></w:r>
<w:commentRangeEnd w:id="0"/>
<w:r>
  <w:commentReference w:id="0"/>
</w:r>

<!-- In comments.xml -->
<w:comment w:id="0" w:author="John Doe" w:initials="JD" w:date="2024-01-15T10:30:00Z">
  <w:p>
    <w:r><w:t>Comment text here</w:t></w:r>
  </w:p>
</w:comment>
```

**PROPOSED:** Build a custom DOCX generator or modify html-to-docx

```typescript
// PROPOSED: Extract comments during export
async function exportWithComments(
  value: Value,
  discussions: Discussion[]
): Promise<Blob> {
  // 1. Find all comment marks in content
  const commentRanges = findCommentRanges(value);

  // 2. Build comments.xml content
  const commentsXml = buildCommentsXml(discussions);

  // 3. Inject comment ranges into document
  const documentWithComments = injectCommentRanges(value, commentRanges);

  // 4. Generate DOCX with both document.xml and comments.xml
  return generateDocxWithComments(documentWithComments, commentsXml);
}
```

## html-to-docx Limitations

The current library has limited support for:

1. **Tracked changes** - No native `<w:ins>`/`<w:del>` generation
2. **Comments** - No comments.xml generation
3. **Custom XML parts** - Limited control over DOCX internals

### Potential Solutions

1. **Enhance html-to-docx** - Add tracked changes/comments support
2. **Use docx.js** - More control but more complex
3. **Custom DOCX builder** - Full control, most work
4. **Post-process DOCX** - Modify ZIP after generation

## Testing Export

### Test Cases Needed

```typescript
describe("DOCX Export", () => {
  it("should export suggestions as tracked changes", async () => {
    const value = [
      {
        type: "p",
        children: [
          { text: "Normal " },
          {
            text: "inserted",
            [KEYS.suggestion]: true,
            [getSuggestionKey("1")]: { id: "1", type: "insert", userId: "John" }
          },
          { text: " text" }
        ]
      }
    ];

    const blob = await exportToDocx(value);
    const docx = await parseDocx(blob);

    expect(docx).toContainElement("w:ins");
    expect(docx.getAttribute("w:author")).toBe("John");
  });

  it("should export comments with ranges", async () => {
    // Similar test for comments
  });

  it("should round-trip successfully", async () => {
    // Import → Export → Import and compare
  });
});
```

## Round-Trip Fidelity

The ultimate goal is round-trip fidelity:

```
Original .docx
     ↓ Import
Plate Editor (suggestions, comments visible)
     ↓ Export
New .docx (tracked changes, Word comments)
     ↓ Import
Plate Editor (identical to step 2)
```

### What Must Be Preserved

| Element | Import → | Editor | → Export |
|---------|----------|--------|----------|
| w:ins | Suggestion (insert) | ✓ | w:ins |
| w:del | Suggestion (remove) | ✓ | w:del |
| w:comment | Discussion | ✓ | w:comment |
| Author | userId | ✓ | Author |
| Date | createdAt | ✓ | Date |
| Content | text | ✓ | Content |

## Export TODO List

- [ ] Create serializer for suggestions → `<ins>`/`<del>` HTML
- [ ] Create comments.xml builder
- [ ] Modify html-to-docx or switch to docx.js
- [ ] Implement comment range injection
- [ ] Add author/date attribute preservation
- [ ] Test round-trip fidelity
- [ ] Handle nested/overlapping annotations
