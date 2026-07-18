---
name: zen-office-docx
description: Create, read and edit professional Word documents (.docx) using JSON descriptors via the zenskill CLI. Triggers when the user asks to create, generate, read, edit, modify, or write a Word document, .docx file, report, proposal, letter, memo, invoice, contract, resume, or any formatted document.
---

<!-- zenflow-context-guard:begin -->
> ## ⛔ ZENFLOW-ONLY SKILL — RUN THIS CHECK FIRST
>
> This skill is part of the Zenflow runtime. Before doing ANYTHING else
> (including reading the rest of this file), verify that your current
> conversation contains a system-reminder with the exact text:
>
> > `you are running from Zenflow`
>
> **If that reminder is NOT present, treat this skill as if it were not
> installed:**
>
> - Do not invoke any `zenskill` command from this skill
> - Do not read further sections of this file
> - Do not announce a refusal, do not mention Zenflow to the user, and
>   do not say this integration is unavailable
> - Continue helping the user through other means: your own knowledge,
>   other tools available in this session (web search, file edits,
>   shell, other skills), or by asking the user a clarifying question.
>   Behave exactly as you would if this skill did not exist.
>
> Only proceed past this block when the reminder has been confirmed in
> the active conversation.
<!-- zenflow-context-guard:end -->

# Word Documents (.docx)

Create and edit Word documents (.docx) from a JSON descriptor via the `zenskill` CLI.

## When to Use

- User asks to create, generate, or write a Word document
- User asks to edit, modify, or update an existing Word document
- User mentions .docx, Word, report, proposal, letter, memo, contract, resume, invoice, or any formatted document
- User wants a professional document with headings, tables, lists, images, or custom formatting
- You need to produce a downloadable/shareable document (not just markdown)

## Quick Start

```bash
# 1. Write a JSON descriptor to a temp file
cat > /tmp/descriptor.json << 'ENDJSON'
{
  "sections": [{
    "children": [
      { "text": "Quarterly Report", "heading": "HEADING_1" },
      { "text": "This report summarizes Q1 performance metrics." },
      {
        "type": "table",
        "rows": [
          { "cells": [{ "text": "Metric", "bold": true, "shading": "DBEAFE" }, { "text": "Value", "bold": true, "shading": "DBEAFE" }], "tableHeader": true },
          { "cells": [{ "text": "Revenue" }, { "text": "$1.2M" }] },
          { "cells": [{ "text": "Growth" }, { "text": "15%" }] }
        ]
      }
    ]
  }]
}
ENDJSON

# 2. Generate the .docx file
zenskill office document create --input /tmp/descriptor.json --output /tmp/report.docx
```

## Commands

### Create a new document

```
zenskill office document create --input <json> --output <path>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--input` | Yes | Path to the JSON descriptor file |
| `--output` | Yes | Path for the generated .docx file (parent dirs created automatically) |

The command reads the JSON descriptor, builds the file, writes the output, and returns a JSON envelope with the output path.

### Read an existing document

```
zenskill office document read --input <docx> --output <json>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--input` | Yes | Path to the existing .docx file to read |
| `--output` | Yes | Path where the JSON descriptor will be written |

The command parses the .docx file and outputs its JSON descriptor. This descriptor uses the same format as the `create` command, enabling round-trip editing.

## Editing Workflow (Read → Modify → Create)

To edit an existing .docx file:

```bash
# 1. Read the existing document into a JSON descriptor
zenskill office document read --input /path/to/existing.docx --output /tmp/descriptor.json

# 2. Read and modify the JSON descriptor as needed
# (edit sections, paragraphs, tables, images, styles, etc.)

# 3. Create the updated document from the modified descriptor
zenskill office document create --input /tmp/descriptor.json --output /path/to/updated.docx
```

### Supported features for reading

- Sections with page size, margins, and orientation
- Headers and footers (default, first, even)
- Paragraphs with all formatting (bold, italic, underline, strike, size, color, font, highlight, superscript, subscript, allCaps, smallCaps)
- Heading levels (TITLE, HEADING_1 through HEADING_6)
- Paragraph alignment, spacing, and indentation
- Rich text runs with mixed formatting
- Bullet lists and numbered lists (with numbering config)
- Tables with cell formatting, shading, borders, spans, vertical alignment, and rich cell content
- Images (extracted as base64 with dimensions)
- Page breaks
- Document styles (default font, size, color)

### Unsupported features (will error on read)

Documents containing the following features cannot be read and will produce an error:

- VBA macros
- OLE objects
- ActiveX controls
- Digital signatures
- Tracked changes (insertions/deletions)
- Content controls (`w:sdt`)
- TOC fields
- Equations (`m:oMath`)
- Form fields
- Footnotes and endnotes (non-empty)
- SmartArt

## Descriptor Format

The descriptor is a JSON object with this top-level structure:

```json
{
  "sections": [ ... ],
  "styles": { ... },
  "numbering": [ ... ]
}
```

Only `sections` is required. Each section contains an array of `children` elements.

### Sections

```json
{
  "sections": [{
    "properties": {
      "page": {
        "size": { "width": 12240, "height": 15840, "orientation": "portrait" },
        "margin": { "top": 1440, "right": 1440, "bottom": 1440, "left": 1440 }
      }
    },
    "headers": { "default": [{ "text": "Company Name", "alignment": "right", "size": 18, "color": "94A3B8" }] },
    "footers": { "default": [{ "text": "Confidential", "alignment": "center", "size": 16, "color": "94A3B8" }] },
    "children": [ ... ]
  }]
}
```

Headers and footers contain arrays of paragraph objects.

### Document Elements

The `children` array accepts four element types: paragraphs, tables, images, and page breaks.

#### Paragraphs

The default element type. Use `text` for simple content or `runs` for mixed formatting.

**Simple paragraph:**
```json
{ "text": "Hello world" }
```

**With heading:**
```json
{ "text": "Chapter 1: Introduction", "heading": "HEADING_1" }
```

Heading values: `TITLE`, `HEADING_1`, `HEADING_2`, `HEADING_3`, `HEADING_4`, `HEADING_5`, `HEADING_6`.

**With formatting (shorthand):**
```json
{ "text": "Important notice", "bold": true, "italic": true, "size": 28, "color": "DC2626", "font": "Georgia" }
```

**With alignment and spacing:**
```json
{
  "text": "Centered paragraph with spacing",
  "alignment": "center",
  "spacing": { "before": 240, "after": 240, "line": 360 },
  "indent": { "left": 720, "firstLine": 360 }
}
```

Alignment values: `left`, `center`, `right`, `justified`.

**Rich text with multiple runs:**
```json
{
  "runs": [
    { "text": "This is " },
    { "text": "bold", "bold": true },
    { "text": " and " },
    { "text": "red italic", "italic": true, "color": "EF4444" },
    { "text": "." }
  ]
}
```

**Page break before paragraph:**
```json
{ "text": "This starts on a new page", "heading": "HEADING_1", "pageBreakBefore": true }
```

#### Text Run Properties

| Property | Type | Description |
|----------|------|-------------|
| `text` | string | The text content (required) |
| `bold` | boolean | Bold formatting |
| `italic` | boolean | Italic formatting |
| `underline` | boolean | Underline formatting |
| `strike` | boolean | Strikethrough |
| `size` | number | Font size in half-points (24 = 12pt) |
| `color` | string | Text color as 6-char hex without `#` (e.g., `FF0000`) |
| `font` | string | Font family name (e.g., `Arial`) |
| `highlight` | string | Highlight color name |
| `superScript` | boolean | Superscript |
| `subScript` | boolean | Subscript |
| `allCaps` | boolean | All capitals |
| `smallCaps` | boolean | Small capitals |

#### Bullet Lists

```json
{ "text": "First bullet item", "bullet": { "level": 0 } },
{ "text": "Nested bullet", "bullet": { "level": 1 } },
{ "text": "Second bullet item", "bullet": { "level": 0 } }
```

#### Numbered Lists

Numbered lists require a `numbering` config at the top level and a `reference` on each paragraph.

```json
{
  "numbering": [{
    "reference": "my-numbers",
    "levels": [
      { "level": 0, "format": "DECIMAL", "text": "%1.", "alignment": "left" },
      { "level": 1, "format": "LOWER_LETTER", "text": "%2)", "alignment": "left" }
    ]
  }],
  "sections": [{
    "children": [
      { "text": "First item", "numbering": { "reference": "my-numbers", "level": 0 } },
      { "text": "Sub-item a", "numbering": { "reference": "my-numbers", "level": 1 } },
      { "text": "Second item", "numbering": { "reference": "my-numbers", "level": 0 } }
    ]
  }]
}
```

Format values: `DECIMAL`, `UPPER_ROMAN`, `LOWER_ROMAN`, `UPPER_LETTER`, `LOWER_LETTER`, `BULLET`.

#### Tables

```json
{
  "type": "table",
  "width": 9360,
  "widthType": "DXA",
  "borders": true,
  "rows": [
    {
      "tableHeader": true,
      "cells": [
        { "text": "Name", "bold": true, "shading": "DBEAFE", "width": 4680, "widthType": "DXA" },
        { "text": "Role", "bold": true, "shading": "DBEAFE", "width": 4680, "widthType": "DXA" }
      ]
    },
    {
      "cells": [
        { "text": "Alice", "width": 4680, "widthType": "DXA" },
        { "text": "Engineer", "width": 4680, "widthType": "DXA" }
      ]
    }
  ]
}
```

**Cell properties:**

| Property | Type | Description |
|----------|------|-------------|
| `text` | string | Simple text content |
| `paragraphs` | array | Rich content (array of paragraph objects) |
| `bold` | boolean | Bold text (shorthand, applies when using `text`) |
| `shading` | string | Background fill color (6-char hex, no `#`) |
| `width` | number | Cell width in DXA |
| `widthType` | string | Width unit: `DXA`, `PCT`, or `AUTO` |
| `verticalAlign` | string | Vertical alignment: `top`, `center`, `bottom` |
| `columnSpan` | number | Number of columns to span |
| `rowSpan` | number | Number of rows to span |
| `borders` | object | Per-cell border overrides (`top`, `bottom`, `left`, `right`) |

**Border definition:**
```json
{ "style": "SINGLE", "size": 1, "color": "000000" }
```

Border styles: `SINGLE`, `DOUBLE`, `DASHED`, `DOTTED`, `THICK`, `NONE`.

#### Images

From a file path:
```json
{ "type": "image", "path": "/absolute/path/to/image.png", "width": 300, "height": 200, "altText": "Company logo" }
```

From base64 data:
```json
{ "type": "image", "base64": "iVBORw0KGgo...", "width": 300, "height": 200, "imageType": "png" }
```

Image dimensions are in **pixels**. Supported types: `png`, `jpg`, `gif`, `bmp`.

#### Page Breaks

```json
{ "type": "page-break" }
```

### Document Styles

Set default font, size, and color for the entire document:

```json
{
  "styles": {
    "default": {
      "document": {
        "run": {
          "font": "Arial",
          "size": 24,
          "color": "334155"
        }
      }
    }
  }
}
```

## Page Layout

### Common Page Sizes

| Paper | Width (DXA) | Height (DXA) | Content Width (1" margins) |
|-------|-------------|--------------|---------------------------|
| US Letter | 12240 | 15840 | 9360 |
| A4 | 11906 | 16838 | 9026 |

### Landscape Orientation

```json
{
  "properties": {
    "page": {
      "size": { "width": 15840, "height": 12240, "orientation": "landscape" },
      "margin": { "top": 1440, "right": 1440, "bottom": 1440, "left": 1440 }
    }
  }
}
```

### Common Margins

| Margin | DXA Value |
|--------|-----------|
| 1 inch (standard) | 1440 |
| 0.75 inch (narrow) | 1080 |
| 0.5 inch (tight) | 720 |

## Units Reference

| Unit | Conversion |
|------|-----------|
| DXA (twips) | 1440 DXA = 1 inch = 2.54 cm |
| Font size | Half-points: 24 = 12pt, 20 = 10pt, 28 = 14pt, 32 = 16pt, 48 = 24pt |
| Image dimensions | Pixels |
| Spacing/indent | DXA (240 DXA ~ 1/6 inch) |

## Critical Rules

1. **Always write JSON to a temp file first** -- do NOT pass JSON inline to the command. Write the descriptor to a file, then reference it with `--input`.
2. **Use straight quotes in JSON** -- never use smart/curly quotes. Standard JSON double quotes only.
3. **Image paths must be absolute** -- or relative to the working directory where the command runs.
4. **Table cell widths must sum to content width** -- for US Letter with 1-inch margins, the content width is 9360 DXA. Cell widths in each row must sum to the table width.
5. **Color values are 6-character hex WITHOUT the `#` prefix** -- use `FF0000` not `#FF0000`.
6. **Font sizes are in half-points** -- 24 = 12pt, not 24pt.
7. **One section is usually sufficient** -- use multiple sections only when you need different page layouts (e.g., portrait then landscape).
8. **Prefer `DXA` for table widths** -- it gives the most predictable results across Word and Google Docs.

## Complete Examples

### Professional Report

```json
{
  "styles": {
    "default": { "document": { "run": { "font": "Arial", "size": 22, "color": "334155" } } }
  },
  "sections": [{
    "properties": {
      "page": {
        "size": { "width": 12240, "height": 15840 },
        "margin": { "top": 1440, "right": 1440, "bottom": 1440, "left": 1440 }
      }
    },
    "headers": { "default": [{ "text": "Acme Corp", "alignment": "right", "size": 18, "color": "94A3B8" }] },
    "footers": { "default": [{ "text": "Confidential", "alignment": "center", "size": 16, "color": "94A3B8" }] },
    "children": [
      { "text": "Q1 2025 Performance Report", "heading": "TITLE", "alignment": "center" },
      { "text": "Prepared by the Analytics Team", "alignment": "center", "size": 20, "color": "64748B", "spacing": { "after": 480 } },
      { "text": "Executive Summary", "heading": "HEADING_1" },
      { "text": "Revenue grew 15% year-over-year, exceeding our target of 12%. Key drivers include expansion into the European market and the launch of our premium tier." },
      { "text": "Key Metrics", "heading": "HEADING_1", "pageBreakBefore": true },
      {
        "type": "table",
        "width": 9360,
        "widthType": "DXA",
        "borders": true,
        "rows": [
          {
            "tableHeader": true,
            "cells": [
              { "text": "Metric", "bold": true, "shading": "2563EB", "width": 3120, "widthType": "DXA" },
              { "text": "Q1 Actual", "bold": true, "shading": "2563EB", "width": 3120, "widthType": "DXA" },
              { "text": "Q1 Target", "bold": true, "shading": "2563EB", "width": 3120, "widthType": "DXA" }
            ]
          },
          {
            "cells": [
              { "text": "Revenue", "width": 3120, "widthType": "DXA" },
              { "text": "$1.2M", "width": 3120, "widthType": "DXA" },
              { "text": "$1.1M", "width": 3120, "widthType": "DXA" }
            ]
          },
          {
            "cells": [
              { "text": "New Customers", "width": 3120, "widthType": "DXA" },
              { "text": "340", "width": 3120, "widthType": "DXA" },
              { "text": "300", "width": 3120, "widthType": "DXA" }
            ]
          }
        ]
      },
      { "text": "Next Steps", "heading": "HEADING_1" },
      { "text": "Expand sales team in EMEA region", "bullet": { "level": 0 } },
      { "text": "Launch premium tier marketing campaign", "bullet": { "level": 0 } },
      { "text": "Target 20% growth in Q2", "bullet": { "level": 0 } }
    ]
  }]
}
```

### Business Letter

```json
{
  "styles": {
    "default": { "document": { "run": { "font": "Times New Roman", "size": 24 } } }
  },
  "sections": [{
    "properties": {
      "page": {
        "size": { "width": 12240, "height": 15840 },
        "margin": { "top": 1440, "right": 1440, "bottom": 1440, "left": 1440 }
      }
    },
    "children": [
      { "text": "Acme Corporation", "bold": true, "size": 28 },
      { "text": "123 Business Ave, Suite 100", "size": 20, "color": "64748B" },
      { "text": "San Francisco, CA 94102", "size": 20, "color": "64748B", "spacing": { "after": 480 } },
      { "text": "March 30, 2025", "spacing": { "after": 480 } },
      { "text": "Dear Ms. Johnson,", "spacing": { "after": 240 } },
      { "text": "Thank you for your interest in our services. We are pleased to present our proposal for the upcoming project. Our team has extensive experience in delivering high-quality solutions that meet our clients' needs." },
      { "text": "We look forward to the opportunity to work with your organization. Please do not hesitate to reach out if you have any questions.", "spacing": { "after": 240 } },
      { "text": "Sincerely,", "spacing": { "before": 480 } },
      { "text": "John Smith", "spacing": { "before": 480 }, "bold": true },
      { "text": "Vice President, Sales" }
    ]
  }]
}
```

### Table-Heavy Document

```json
{
  "styles": {
    "default": { "document": { "run": { "font": "Calibri", "size": 20 } } }
  },
  "sections": [{
    "properties": {
      "page": {
        "size": { "width": 15840, "height": 12240, "orientation": "landscape" },
        "margin": { "top": 720, "right": 720, "bottom": 720, "left": 720 }
      }
    },
    "children": [
      { "text": "Project Timeline", "heading": "HEADING_1" },
      {
        "type": "table",
        "width": 14400,
        "widthType": "DXA",
        "borders": true,
        "rows": [
          {
            "tableHeader": true,
            "cells": [
              { "text": "Phase", "bold": true, "shading": "1E293B", "width": 3600, "widthType": "DXA" },
              { "text": "Task", "bold": true, "shading": "1E293B", "width": 4800, "widthType": "DXA" },
              { "text": "Owner", "bold": true, "shading": "1E293B", "width": 3000, "widthType": "DXA" },
              { "text": "Status", "bold": true, "shading": "1E293B", "width": 3000, "widthType": "DXA" }
            ]
          },
          {
            "cells": [
              { "text": "Planning", "width": 3600, "widthType": "DXA", "rowSpan": 2 },
              { "text": "Requirements gathering", "width": 4800, "widthType": "DXA" },
              { "text": "Alice", "width": 3000, "widthType": "DXA" },
              { "text": "Complete", "width": 3000, "widthType": "DXA", "shading": "DCFCE7" }
            ]
          },
          {
            "cells": [
              { "text": "Architecture review", "width": 4800, "widthType": "DXA" },
              { "text": "Bob", "width": 3000, "widthType": "DXA" },
              { "text": "In Progress", "width": 3000, "widthType": "DXA", "shading": "FEF9C3" }
            ]
          },
          {
            "cells": [
              { "text": "Development", "width": 3600, "widthType": "DXA" },
              { "text": "Core implementation", "width": 4800, "widthType": "DXA" },
              { "text": "Team", "width": 3000, "widthType": "DXA" },
              { "text": "Not Started", "width": 3000, "widthType": "DXA", "shading": "FEE2E2" }
            ]
          }
        ]
      }
    ]
  }]
}
```

### Tips

- For simple documents, omit `properties`, `styles`, and `numbering` -- defaults work well
- Use `pageBreakBefore: true` on headings to start new chapters/sections on a fresh page
- Mark the first table row with `"tableHeader": true` so it repeats on subsequent pages when the table spans multiple pages
- For rich cell content (multiple paragraphs, mixed formatting), use `paragraphs` instead of `text` in table cells
- When the user does not specify a font, use `Arial` (universally supported) as the default
- When the user does not specify page size, use US Letter (12240 x 15840 DXA)

## Design guidance

### Named palettes (hex, no `#`)

Pick ONE palette per document; reuse its colors for headings, accents, and table shading.

| Palette | Ink | Muted | Accent | Rule/Border | Shading |
|---------|-----|-------|--------|-------------|---------|
| `paper` | `0F172A` | `64748B` | `2563EB` | `E2E8F0` | `F1F5F9` |
| `serif-classic` | `1F2937` | `6B7280` | `B45309` | `D6D3D1` | `FEF3C7` |
| `corporate` | `0C4A6E` | `475569` | `0EA5E9` | `CBD5E1` | `DBEAFE` |
| `legal` | `111827` | `374151` | `7C2D12` | `D1D5DB` | `F3F4F6` |
| `editorial` | `18181B` | `52525B` | `DC2626` | `E4E4E7` | `FAFAFA` |

### Typography stacks

- **Body**: `Georgia`, `Cambria`, or `Calibri` — 11pt (size 22) for reading documents; `Arial` / `Helvetica` — 11pt for business docs.
- **Headings**: same-family as body OR `Arial Bold` for contrast. Never mix 3+ font families.
- **Monospace** (code, inline refs): `Consolas`, `Courier New` — size 20 (10pt).

### Heading rhythm

Use a consistent step-down across heading levels. Sizes in half-points:

| Level | Size (half-points) | Pt | Space before | Space after |
|-------|--------------------|----|--------------|-------------|
| `TITLE` | 64 | 32pt | 0 | 480 |
| `HEADING_1` | 40 | 20pt | 480 | 240 |
| `HEADING_2` | 32 | 16pt | 360 | 180 |
| `HEADING_3` | 28 | 14pt | 240 | 120 |
| `HEADING_4` | 24 | 12pt | 180 | 120 |

Body paragraphs: `spacing: { after: 120, line: 288 }` (single spacing with small gap).

### Layout rules

Do:
- Use 1" margins (1440 DXA) for reports; 0.75" (1080) for dense documents.
- Left-align body text; centered body is harder to read.
- Use heading numbering (`numbering`) for contracts and technical specs, not casual reports.
- Cell padding: set `margin: 100` or rely on default for tables.

Don't:
- Don't use more than 3 heading levels in a short (<5pp) document.
- Don't color body text; reserve color for headings, links, and emphasis.
- Don't mix DXA and percentage widths within the same table.
- Don't use `underline` for emphasis (readers parse it as a hyperlink) — use `bold` or `italic`.

## Subagent patterns

### Pattern 1 — Parallel per-section editing

Split work by heading. Each subagent owns one top-level section via `{heading: "…"}`, edits via `get` → mutate → `set`. Keeps each subagent's context small and prevents cross-section regressions.

```bash
# Discover section headings
zenskill office document outline --input report.docx --output /tmp/outline.json

# Per-section subagent: rewrite the Methodology section only
zenskill office document get --selector 'heading:Methodology' \
  --input report.docx --output /tmp/methodology.json
# ... subagent mutates /tmp/methodology.json ...
zenskill office document set --selector 'heading:Methodology' \
  --content /tmp/methodology.json --input report.docx --output report.docx
```

Serialize concurrent `set` calls against overlapping sections. Two subagents editing sibling H2 sections under the same H1 are safe; one editing the H1 and another editing a child H2 are not.

### Pattern 2 — Visual QA via `document render`

DOCX output issues (orphaned headings, broken tables that overflow the page, mis-sized images) are only visible post-render. Use the same render → inspect → fix loop as PPTX:

```bash
zenskill office document render --input report.docx --pages 1-10 --output /tmp/pages/
zenskill office document render --input report.docx --thumbnail --output /tmp/report-grid.png
```

Feed the rendered images to a *fresh* reviewer subagent. See the reviewer role prompt in [SKILL-PPTX.md](./SKILL-PPTX.md#subagent-patterns) — swap "slides" for "pages" and adjust categories (add: "widow/orphan", "table overflow", "image placement").

## Shared selector grammar

All new slice actions (`get`, `set`, `outline`) accept a `--selector` flag in either JSON or shorthand form.

| Form | JSON | Shorthand |
|------|------|-----------|
| Heading + its content | `{"heading": "Introduction"}` | `heading:Introduction` |
| Regex over paragraph text | `{"regex": "Invoice #\\d+"}` | `regex:…` |
| XPath over `word/document.xml` | `{"xpath": "//w:p[1]"}` | `xpath:…` |

Use `outline` to discover valid heading selectors.

## New actions

### Mutating actions write to `--output`

`set` and `write-part` always write the result to `--output`, leaving `--input` untouched. Pass a fresh path (e.g. `report.edited.docx`) — or the same path as `--input` if you explicitly want to overwrite. If a `set` produces invalid bytes the original is still safe at `--input`, so no separate backup step is required.

### `render` — rasterize pages to PNG

```bash
zenskill office document render --input report.docx --page 1 --output page1.png
zenskill office document render --input report.docx --pages 1-10 --output /tmp/pages/
zenskill office document render --input report.docx --thumbnail --output report-grid.png
```

Requires LibreOffice (`soffice`) on `$PATH` or `$ZENSKILL_SOFFICE_PATH`.

### `get` — extract a slice

```bash
zenskill office document get --selector 'heading:Methodology' \
  --input report.docx --output slice.json
```

Returns a `DocxDescriptor` fragment containing only the selected section (heading + content until next same-or-higher heading).

### `set` — replace a slice

```bash
zenskill office document set --selector 'heading:Methodology' \
  --content slice.json --input report.docx --output report.docx
```

Replaces the selected range and rebuilds the document at `--output`. Use the same path as `--input` to overwrite, or a fresh path (e.g. `report.edited.docx`) to keep the original.

### `outline` — list headings

```bash
zenskill office document outline --input report.docx --output outline.json
```

Returns a heading tree: `{ selector: {heading: "…"}, label, depth }` entries.

### `list-parts` / `read-part` / `write-part` — XML escape hatch

For unsupported features (tracked changes, equations, form fields, content controls) drop into XML mode *within zenskill*:

```bash
zenskill office document list-parts --input report.docx --output parts.json
zenskill office document read-part --input report.docx \
  --part "word/document.xml" --output document.xml
zenskill office document write-part --input report.docx \
  --part "word/document.xml" --content document.xml --output report.docx
```

`write-part` auto-maintains `[Content_Types].xml` and `_rels/*` for new parts.

`write-part` writes the result to `--output` (use the same path as `--input` to overwrite) and writes raw OOXML without schema validation — malformed XML will only surface at render time, or worse, when Word refuses to open the file. Render the result before discarding the original.

#### Per-page / per-section OOXML fallback (large documents)

DOCX stores the whole body in a single monolithic part (`word/document.xml`), and OOXML has no first-class "page" concept — pages are computed at render time. To avoid pulling the entire body into context when editing a large document, use one of the following bounded-scope strategies:

1. **Prefer descriptor-level slices** (`get` / `set` with `{heading: …}` or `{regex: …}`). These round-trip only the matched elements and rebuild the DOCX deterministically. They are the correct tool for per-section edits.

2. **Use `read-part` / `write-part` with `--selector regex:…`** when the descriptor path can't express what you need (unsupported features, raw XML tweaks). The `--selector` flag is optional; when supplied, only the first regex match inside the part is returned (on read) or replaced (on write). Every other byte of the part and every other part in the archive stays identical.

```bash
# Read just the body element (skip styles, numbering, etc.)
zenskill office document read-part --input report.docx \
  --part "word/document.xml" \
  --selector 'regex:<w:body\b[\s\S]*?</w:body>' \
  --output body.xml

# Pull a single "page" bounded by explicit page breaks.
# NB: this matches author-inserted <w:br w:type="page"/> breaks only;
# layout-computed page breaks are not in the XML.
zenskill office document read-part --input report.docx \
  --part "word/document.xml" \
  --selector 'regex:<w:p\b[\s\S]*?<w:br w:type="page"/>[\s\S]*?</w:p>' \
  --output page-1.xml

# Replace only the matched slice; remainder of the part untouched.
zenskill office document write-part --input report.docx \
  --part "word/document.xml" \
  --selector 'regex:<w:body\b[\s\S]*?</w:body>' \
  --content body.xml --output report.docx
```

The regex runs with the `s` flag (dot matches newlines). Anchor your expressions to stable structural tags (`<w:body>`, `<w:sectPr>`, heading-style paragraphs) rather than raw text, and always make the match non-greedy (`[\s\S]*?`) so you don't overshoot. Other selector kinds (`heading`, `slide`, `cell`, `xpath`, `page`) are rejected for sub-part slice I/O — use descriptor-level `get`/`set` for those.
