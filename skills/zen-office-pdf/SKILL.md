---
name: zen-office-pdf
description: Create and read PDF documents (.pdf) using JSON descriptors via the zenskill CLI. Triggers when the user asks to create, generate, or write a PDF document, or mentions .pdf, PDF, portable document, or needs a fixed-layout document.
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

# PDF Documents (.pdf)

Create and read PDF documents (.pdf) via the `zenskill` CLI.

## When to Use

- User asks to create, generate, or write a PDF document
- User asks to read, inspect, or extract content from an existing PDF
- User mentions .pdf, PDF, portable document, or needs a fixed-layout document
- You need to produce a downloadable/shareable PDF (not just markdown)

## Quick Start

```bash
# 1. Write a JSON descriptor to a temp file
cat > /tmp/descriptor.json << 'ENDJSON'
{
  "title": "My Document",
  "pages": [{
    "elements": [
      { "type": "text", "text": "Hello World", "x": 50, "y": 750, "size": 24, "font": "Helvetica-Bold" },
      { "type": "text", "text": "This is a PDF document.", "x": 50, "y": 720, "size": 12 }
    ]
  }]
}
ENDJSON

# 2. Generate the .pdf file
zenskill office pdf create --input /tmp/descriptor.json --output /tmp/document.pdf
```

## Commands

### Create a new PDF

```
zenskill office pdf create --input <json> --output <path>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--input` | Yes | Path to the JSON descriptor file |
| `--output` | Yes | Path for the generated .pdf file (parent dirs created automatically) |

The command reads the JSON descriptor, builds the file, writes the output, and returns a JSON envelope with the output path.

### Read an existing PDF

```
zenskill office pdf read --input <pdf> --output <json>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--input` | Yes | Path to the existing .pdf file to read |
| `--output` | Yes | Path where the JSON descriptor will be written |

The command parses the .pdf file and outputs a JSON descriptor containing metadata (title, author, subject, creator, producer), page dimensions, and extracted text content.

**⚠️ IMPORTANT — READ-ONLY: Do NOT attempt to edit PDFs by reading and re-creating them.** PDF is a fixed-layout format where text positions, font metrics, and rendering details cannot be reliably round-tripped. Reading a PDF and creating a new one from the extracted descriptor will almost certainly mangle formatting, lose layout fidelity, and produce a broken document. Use the `read` action only for inspecting content, extracting text, or understanding what a PDF contains. If the user needs to modify a PDF, recommend editing the source document (e.g., .docx, .pptx) and re-exporting to PDF instead.

### What the read output contains

- **Metadata**: title, author, subject, creator, producer (when present in the PDF)
- **Page dimensions**: width and height in points for each page
- **Text content**: extracted text per page as a single text element (positions are approximate — not the original element layout)

The read output is **not suitable for round-trip editing** because PDF text extraction produces plain text, not the original positioned elements, fonts, or styling.

## Descriptor Format

The descriptor is a JSON object with this top-level structure:

```json
{
  "title": "Document Title",
  "author": "Author Name",
  "subject": "Subject",
  "creator": "Creator App",
  "producer": "Producer App",
  "pages": [ ... ]
}
```

Only `pages` is required. Each page contains an array of `elements` to draw.

### Page Configuration

```json
{
  "pages": [{
    "width": 595,
    "height": 842,
    "elements": [ ... ]
  }]
}
```

Default page size is **A4** (595 x 842 points). PDF coordinates use a bottom-left origin: `(0, 0)` is the bottom-left corner, `y` increases upward.

### Common Page Sizes (points)

| Paper | Width | Height |
|-------|-------|--------|
| A4 (default) | 595 | 842 |
| US Letter | 612 | 792 |
| US Legal | 612 | 1008 |

### Element Types

Each element has a `type` field. Available types: `text`, `rect`, `line`, `circle`, `image`.

#### Text

```json
{
  "type": "text",
  "text": "Hello World",
  "x": 50,
  "y": 750,
  "size": 16,
  "font": "Helvetica-Bold",
  "color": { "r": 0.0, "g": 0.0, "b": 0.0 },
  "opacity": 1.0,
  "rotate": 0
}
```

**Text with wrapping** (requires both `maxWidth` and `lineHeight`):
```json
{
  "type": "text",
  "text": "This is a long paragraph that will wrap automatically when it exceeds the maximum width.",
  "x": 50,
  "y": 700,
  "size": 12,
  "font": "Helvetica",
  "maxWidth": 500,
  "lineHeight": 16
}
```

**Text element properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `text` | string | Yes | The text content |
| `x` | number | Yes | X position in points |
| `y` | number | Yes | Y position in points (from bottom) |
| `size` | number | No | Font size in points (default: 12) |
| `font` | string | No | Font name (default: `Helvetica`) |
| `color` | PdfColor | No | Text color (default: black) |
| `opacity` | number | No | Opacity 0.0-1.0 |
| `maxWidth` | number | No | Max width before wrapping |
| `lineHeight` | number | No | Line height for wrapped text |
| `rotate` | number | No | Rotation in degrees |

#### Rectangle

```json
{
  "type": "rect",
  "x": 50,
  "y": 600,
  "width": 200,
  "height": 100,
  "color": { "r": 0.23, "g": 0.51, "b": 0.96 },
  "borderColor": { "r": 0.0, "g": 0.0, "b": 0.0 },
  "borderWidth": 2,
  "opacity": 1.0
}
```

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `x` | number | Yes | X position |
| `y` | number | Yes | Y position |
| `width` | number | Yes | Rectangle width |
| `height` | number | Yes | Rectangle height |
| `color` | PdfColor | No | Fill color |
| `borderColor` | PdfColor | No | Border color |
| `borderWidth` | number | No | Border width in points |
| `opacity` | number | No | Opacity 0.0-1.0 |
| `rotate` | number | No | Rotation in degrees |

#### Line

```json
{
  "type": "line",
  "startX": 50,
  "startY": 500,
  "endX": 550,
  "endY": 500,
  "color": { "r": 0.5, "g": 0.5, "b": 0.5 },
  "thickness": 1,
  "dashArray": [5, 3],
  "dashPhase": 0
}
```

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `startX` | number | Yes | Start X position |
| `startY` | number | Yes | Start Y position |
| `endX` | number | Yes | End X position |
| `endY` | number | Yes | End Y position |
| `color` | PdfColor | No | Line color |
| `thickness` | number | No | Line thickness (default: 1) |
| `opacity` | number | No | Opacity 0.0-1.0 |
| `dashArray` | number[] | No | Dash pattern (e.g., `[5, 3]`) |
| `dashPhase` | number | No | Dash phase offset |

#### Circle

```json
{
  "type": "circle",
  "x": 300,
  "y": 400,
  "radius": 50,
  "color": { "r": 1.0, "g": 0.0, "b": 0.0 },
  "borderColor": { "r": 0.0, "g": 0.0, "b": 0.0 },
  "borderWidth": 1
}
```

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `x` | number | Yes | Center X position |
| `y` | number | Yes | Center Y position |
| `radius` | number | Yes | Circle radius |
| `color` | PdfColor | No | Fill color |
| `borderColor` | PdfColor | No | Border color |
| `borderWidth` | number | No | Border width |
| `opacity` | number | No | Opacity 0.0-1.0 |

#### Image

From file path:
```json
{
  "type": "image",
  "x": 50,
  "y": 300,
  "width": 200,
  "height": 150,
  "path": "/absolute/path/to/image.png",
  "imageType": "png"
}
```

From base64:
```json
{
  "type": "image",
  "x": 50,
  "y": 300,
  "width": 200,
  "height": 150,
  "base64": "iVBORw0KGgo...",
  "imageType": "png"
}
```

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `x` | number | Yes | X position |
| `y` | number | Yes | Y position |
| `width` | number | Yes | Display width |
| `height` | number | Yes | Display height |
| `path` | string | No* | File path to image |
| `base64` | string | No* | Base64-encoded image data |
| `imageType` | string | No | `png` or `jpg` (auto-detected from path extension) |
| `opacity` | number | No | Opacity 0.0-1.0 |
| `rotate` | number | No | Rotation in degrees |

*Either `path` or `base64` is required.

### Color Format

Colors use **RGB float values** from 0.0 to 1.0:

```json
{ "r": 0.0, "g": 0.0, "b": 0.0 }
```

| Color | Value |
|-------|-------|
| Black | `{ "r": 0.0, "g": 0.0, "b": 0.0 }` |
| White | `{ "r": 1.0, "g": 1.0, "b": 1.0 }` |
| Red | `{ "r": 1.0, "g": 0.0, "b": 0.0 }` |
| Blue | `{ "r": 0.0, "g": 0.0, "b": 1.0 }` |
| Gray | `{ "r": 0.5, "g": 0.5, "b": 0.5 }` |

To convert from hex: divide each component by 255. E.g., `#3B82F6` -> `r: 59/255 ~ 0.23`, `g: 130/255 ~ 0.51`, `b: 246/255 ~ 0.96`.

### Available Fonts

PDF uses the 14 standard PDF fonts (no embedding required):

| Font Name | Variant |
|-----------|---------|
| `Helvetica` | Regular |
| `Helvetica-Bold` | Bold |
| `Helvetica-Oblique` | Italic |
| `Helvetica-BoldOblique` | Bold Italic |
| `TimesRoman` | Regular |
| `TimesRoman-Bold` | Bold |
| `TimesRoman-Italic` | Italic |
| `TimesRoman-BoldItalic` | Bold Italic |
| `Courier` | Regular |
| `Courier-Bold` | Bold |
| `Courier-Oblique` | Italic |
| `Courier-BoldOblique` | Bold Italic |
| `Symbol` | Symbol characters |
| `ZapfDingbats` | Dingbat characters |

Default font is `Helvetica` if not specified.

## Complete Example

```json
{
  "title": "Invoice #1234",
  "author": "Acme Corp",
  "pages": [
    {
      "width": 595,
      "height": 842,
      "elements": [
        {
          "type": "rect",
          "x": 0, "y": 792,
          "width": 595, "height": 50,
          "color": { "r": 0.06, "g": 0.09, "b": 0.16 }
        },
        {
          "type": "text",
          "text": "INVOICE",
          "x": 50, "y": 805,
          "size": 24,
          "font": "Helvetica-Bold",
          "color": { "r": 1.0, "g": 1.0, "b": 1.0 }
        },
        {
          "type": "text",
          "text": "#1234",
          "x": 480, "y": 805,
          "size": 18,
          "font": "Helvetica",
          "color": { "r": 1.0, "g": 1.0, "b": 1.0 }
        },
        {
          "type": "text",
          "text": "Acme Corporation",
          "x": 50, "y": 750,
          "size": 14,
          "font": "Helvetica-Bold"
        },
        {
          "type": "text",
          "text": "123 Business Ave, San Francisco, CA 94102",
          "x": 50, "y": 730,
          "size": 10,
          "color": { "r": 0.4, "g": 0.4, "b": 0.4 }
        },
        {
          "type": "line",
          "startX": 50, "startY": 710,
          "endX": 545, "endY": 710,
          "color": { "r": 0.8, "g": 0.8, "b": 0.8 },
          "thickness": 1
        },
        {
          "type": "text",
          "text": "Bill To: Jane Smith",
          "x": 50, "y": 690,
          "size": 12,
          "font": "Helvetica-Bold"
        },
        {
          "type": "text",
          "text": "Date: 2025-03-30",
          "x": 400, "y": 690,
          "size": 12
        },
        {
          "type": "rect",
          "x": 50, "y": 640,
          "width": 495, "height": 25,
          "color": { "r": 0.86, "g": 0.92, "b": 0.98 }
        },
        {
          "type": "text",
          "text": "Description",
          "x": 55, "y": 648,
          "size": 10,
          "font": "Helvetica-Bold"
        },
        {
          "type": "text",
          "text": "Amount",
          "x": 470, "y": 648,
          "size": 10,
          "font": "Helvetica-Bold"
        },
        {
          "type": "text",
          "text": "Consulting Services - March 2025",
          "x": 55, "y": 625,
          "size": 10
        },
        {
          "type": "text",
          "text": "$5,000.00",
          "x": 465, "y": 625,
          "size": 10
        },
        {
          "type": "line",
          "startX": 50, "startY": 600,
          "endX": 545, "endY": 600,
          "thickness": 1,
          "color": { "r": 0.8, "g": 0.8, "b": 0.8 }
        },
        {
          "type": "text",
          "text": "Total: $5,000.00",
          "x": 420, "y": 580,
          "size": 14,
          "font": "Helvetica-Bold"
        }
      ]
    }
  ]
}
```

## Critical Rules

1. **Always write JSON to a temp file first** -- do NOT pass JSON inline to the command. Write the descriptor to a file, then reference it with `--input`.
2. **Use straight quotes in JSON** -- never use smart/curly quotes. Standard JSON double quotes only.
3. **Image paths must be absolute** -- or relative to the working directory where the command runs.
4. **Colors are RGB float objects (0.0-1.0)** -- use `{ "r": 1.0, "g": 0.0, "b": 0.0 }` not hex strings.
5. **Coordinates use bottom-left origin** -- `y: 0` is the bottom of the page, `y` increases upward.
6. **Only 14 standard PDF fonts are available** -- Helvetica, TimesRoman, Courier and their bold/italic variants, plus Symbol and ZapfDingbats.
7. **Text wrapping requires `maxWidth`** -- `lineHeight` is optional and defaults to `fontSize * 1.2` when omitted.
8. **Image elements support only `png` and `jpg`** -- no gif, bmp, or svg.

## Tips

- PDF coordinates use a **bottom-left origin** -- `y: 0` is the bottom of the page, `y` increases upward
- Default page size is **A4** (595 x 842 points); 1 point = 1/72 inch
- Colors are **RGB floats** (0.0-1.0), NOT hex strings
- **Newline characters (`\n`) are supported** in text elements -- they split text into multiple lines automatically using a default line height of `fontSize * 1.2` (override with `lineHeight`)
- For text wrapping by width, set `maxWidth` (and optionally `lineHeight`) -- newlines within wrapped text are also respected
- To simulate tables, use combinations of `rect`, `line`, and `text` elements with calculated positions
- Elements are drawn in order -- later elements render on top of earlier ones (painter's algorithm)

## Design guidance

### Margins (points; A4 is 595 × 842)

- **Report / document**: `54pt` (0.75") all sides. Content area `487 × 734`.
- **Invoice / letter**: `50pt` side, `60pt` top, `72pt` bottom (room for footer).
- **Book / print-ready**: `72pt` outer + top/bottom; `54pt` spine side.
- **Dense reference / table-heavy**: `36pt` all sides; never go tighter.

Place page numbers at `y: 36` centered; footer text at `y: 30`.

### Typography

- **Body**: `Helvetica` or `TimesRoman` at 10–11pt. TimesRoman reads better for long prose; Helvetica for UI-style/business.
- **Headings**: `Helvetica-Bold` at 18/14/12pt for a three-level hierarchy.
- **Line height**: 1.3–1.4× font size. For 11pt body use `lineHeight: 14` or `15`.
- **Monospace**: `Courier` at 9–10pt for code / IDs.
- Only the 14 standard fonts are available — do not invent font names.

### Named palettes (RGB floats)

Pick ONE per document. `r`, `g`, `b` are 0.0–1.0.

| Palette | Ink | Muted | Accent | Rule |
|---------|-----|-------|--------|------|
| `paper` | `0.06, 0.09, 0.16` | `0.45, 0.49, 0.55` | `0.15, 0.39, 0.92` | `0.88, 0.91, 0.94` |
| `invoice` | `0.11, 0.12, 0.14` | `0.40, 0.40, 0.40` | `0.10, 0.47, 0.31` | `0.85, 0.85, 0.85` |
| `corporate` | `0.05, 0.29, 0.44` | `0.28, 0.34, 0.42` | `0.06, 0.65, 0.91` | `0.80, 0.85, 0.90` |
| `editorial` | `0.09, 0.09, 0.10` | `0.32, 0.32, 0.35` | `0.86, 0.15, 0.15` | `0.89, 0.89, 0.89` |

To convert from hex: `r = hexR / 255`, etc.

### Layout rules

Do:
- Align repeating elements (headers, line items) on a consistent x-grid.
- Use thin horizontal rules (`thickness: 0.5`) for separation — avoid heavy borders.
- Use the `Muted` palette color for captions, dates, metadata.
- For multi-page documents, emit a footer with page number on every page.

Don't:
- Don't use drop shadows or gradients — PDFs print poorly with effects.
- Don't use more than 2 accent colors per page.
- Don't set tiny font sizes (<8pt); they break print legibility.
- Don't position text at `y < margin_bottom` — it clips on many printers.

## Subagent patterns

For parallel editing and visual QA patterns, see the reviewer role prompt and render → inspect → fix loop in [SKILL-PPTX.md](./SKILL-PPTX.md#subagent-patterns) — swap "slide" for "page". PDF is read-only for slice writes, so the "fix" step must rebuild the descriptor from scratch or edit the source (.docx / .pptx) and re-export.

## Shared selector grammar

The `get` and `outline` actions accept a `--selector` flag in JSON or shorthand form.

| Form | JSON | Shorthand |
|------|------|-----------|
| Single page | `{"page": 3}` | `page:3` |
| Page range | `{"pages": "2-4"}` | `pages:2-4` |
| Page list | `{"pages": [1,3,5]}` | `pages:1,3,5` |
| Regex over text | `{"regex": "Invoice #\\d+"}` | `regex:…` |

## New actions

### `render` — rasterize pages to PNG

```bash
# Single page → file
zenskill office pdf render --input doc.pdf --page 1 --output page1.png

# Range → directory (emits slide-01.png, slide-02.png, …)
zenskill office pdf render --input doc.pdf --pages 1-10 --output /tmp/pages/

# Thumbnail grid of the whole PDF
zenskill office pdf render --input doc.pdf --thumbnail --output doc-grid.png
```

PDF rendering does NOT require LibreOffice — it uses bundled `pdfjs-dist`.

### `get` — extract text / descriptor for selected pages

```bash
zenskill office pdf get --selector "page:3" --input doc.pdf --output page3.json
zenskill office pdf get --selector "pages:2-4" --input doc.pdf --output pages.json
```

Returns extracted text and page dimensions. Suitable for inspection, not for re-create round-trips.

### `outline` — list pages and detected headings

```bash
zenskill office pdf outline --input doc.pdf --output outline.json
```

### Not supported on PDF

`set`, `list-parts`, `read-part`, `write-part` return `VALIDATION_ERROR` with the message "PDF is read-only". To modify a PDF, edit the source document (.docx / .pptx) and re-export.
