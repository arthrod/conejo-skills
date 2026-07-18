---
name: zen-office-pptx
description: Create, read and edit professional PowerPoint presentations (.pptx) using JSON descriptors via the zenskill CLI. Triggers when the user asks to create, generate, read, edit, modify, or write a presentation, slide deck, pitch deck, or mentions .pptx, PowerPoint, slides, or keynote.
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

# Presentations (.pptx)

Create and edit PowerPoint presentations (.pptx) from a JSON descriptor via the `zenskill` CLI.

## When to Use

- User asks to create, generate, or write a presentation, slide deck, or pitch deck
- User asks to edit, modify, or update an existing presentation
- User mentions .pptx, PowerPoint, slides, presentation, keynote, or deck
- You need to produce a downloadable/shareable presentation (not just markdown)

## Quick Start

```bash
# 1. Write a JSON descriptor to a temp file
cat > /tmp/descriptor.json << 'ENDJSON'
{
  "layout": "LAYOUT_WIDE",
  "slides": [
    {
      "background": { "color": "0F172A" },
      "elements": [
        { "type": "text", "options": { "x": 1, "y": 2.5, "w": 11, "h": 1.5, "text": "My Presentation", "fontSize": 40, "fontFace": "Arial", "color": "FFFFFF", "bold": true, "align": "center" } }
      ]
    }
  ]
}
ENDJSON

# 2. Generate the .pptx file
zenskill office presentation create --input /tmp/descriptor.json --output /tmp/deck.pptx
```

## Commands

### Create a new presentation

```
zenskill office presentation create --input <json> --output <path>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--input` | Yes | Path to the JSON descriptor file |
| `--output` | Yes | Path for the generated .pptx file (parent dirs created automatically) |

The command reads the JSON descriptor, builds the file, writes the output, and returns a JSON envelope with the output path.

### Read an existing presentation

```
zenskill office presentation read --input <pptx> --output <json>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--input` | Yes | Path to the existing .pptx file to read |
| `--output` | Yes | Path where the JSON descriptor will be written |

The command parses the .pptx file and outputs its JSON descriptor. This descriptor uses the same format as the `create` command, enabling round-trip editing.

## Editing Workflow (Read → Modify → Create)

To edit an existing .pptx file:

```bash
# 1. Read the existing presentation into a JSON descriptor
zenskill office presentation read --input /path/to/existing.pptx --output /tmp/descriptor.json

# 2. Read and modify the JSON descriptor as needed
# (edit slides, elements, text, images, charts, etc.)

# 3. Create the updated presentation from the modified descriptor
zenskill office presentation create --input /tmp/descriptor.json --output /path/to/updated.pptx
```

### Supported features for reading

- Slide layout (LAYOUT_WIDE, LAYOUT_16x10, LAYOUT_4x3)
- Presentation metadata (title, subject, author)
- Slide backgrounds (solid color)
- Slide masters with background and objects
- Text elements with positioning and all formatting (fontSize, fontFace, color, bold, italic, underline, strike, align, valign)
- Multi-run rich text (items with mixed formatting)
- Shapes (rect, roundRect, oval, line) with fill, line, shadow, rectRadius
- Images (extracted as base64 with dimensions and alt text)
- Tables with cell formatting, borders, spans, and text content
- Charts with data series (bar, line, pie, doughnut, scatter, bubble, radar, area)
- Speaker notes
- Slide numbers

### Unsupported features (will error on read)

Documents containing the following features cannot be read and will produce an error:

- VBA macros
- Embedded OLE objects
- SmartArt
- Slicers
- Custom XML

## Descriptor Format

The descriptor is a JSON object with this top-level structure:

```json
{
  "layout": "LAYOUT_WIDE",
  "author": "Author Name",
  "title": "Presentation Title",
  "subject": "Subject",
  "masters": [ ... ],
  "slides": [ ... ]
}
```

Only `slides` is required. Each slide contains an array of `elements`.

### Slide Layouts

| Layout | Width | Height | Aspect |
|--------|-------|--------|--------|
| `LAYOUT_WIDE` (default) | 13.33" | 7.5" | 16:9 |
| `LAYOUT_16x10` | 10" | 6.25" | 16:10 |
| `LAYOUT_4x3` | 10" | 7.5" | 4:3 |

### Slides

```json
{
  "slides": [{
    "background": { "color": "FFFFFF" },
    "masterName": "MY_MASTER",
    "elements": [ ... ],
    "notes": "Speaker notes for this slide",
    "slideNumber": { "x": "90%", "y": "95%", "fontSize": 10, "color": "94A3B8" }
  }]
}
```

### Slide Element Types

Each element has a `type` and an `options` object with positioning (`x`, `y`, `w`, `h` in inches).

#### Text

Simple text:
```json
{
  "type": "text",
  "options": {
    "x": 0.5, "y": 0.5, "w": 8, "h": 1,
    "text": "Hello World",
    "fontSize": 24, "fontFace": "Arial",
    "color": "334155", "bold": true,
    "align": "center", "valign": "middle"
  }
}
```

Multi-run rich text (use `items` for mixed formatting within one text box):
```json
{
  "type": "text",
  "options": { "x": 0.5, "y": 2, "w": 8, "h": 1, "isTextBox": true },
  "items": [
    { "text": "This is ", "fontSize": 18 },
    { "text": "bold", "bold": true, "fontSize": 18 },
    { "text": " and ", "fontSize": 18 },
    { "text": "red", "color": "EF4444", "fontSize": 18 }
  ]
}
```

**Text item properties:**

| Property | Type | Description |
|----------|------|-------------|
| `text` | string | Text content (required) |
| `fontSize` | number | Font size in points |
| `fontFace` | string | Font family name |
| `color` | string | Text color (6-char hex, no `#`) |
| `bold` | boolean | Bold |
| `italic` | boolean | Italic |
| `underline` | boolean | Underline |
| `strike` | boolean | Strikethrough |
| `breakLine` | boolean | Line break before this run |
| `bullet` | boolean/object | Enable bullets |
| `hyperlink` | object | `{ "url": "https://...", "tooltip": "..." }` |
| `subscript` | boolean | Subscript |
| `superscript` | boolean | Superscript |
| `align` | string | `left`, `center`, `right` |

#### Shape

```json
{
  "type": "shape",
  "options": {
    "x": 1, "y": 1, "w": 4, "h": 2,
    "type": "RECT",
    "fill": { "color": "3B82F6" },
    "line": { "color": "1D4ED8", "width": 2 },
    "rectRadius": 0.2,
    "shadow": { "type": "outer", "color": "000000", "blur": 6, "offset": 3, "angle": 45, "opacity": 0.4 }
  }
}
```

Shape types: `RECT`, `ROUNDRECT`, `OVAL`, `LINE`.

#### Image

From file path:
```json
{
  "type": "image",
  "options": { "x": 1, "y": 1, "w": 4, "h": 3, "path": "/path/to/image.png", "altText": "Photo" }
}
```

From base64:
```json
{
  "type": "image",
  "options": { "x": 1, "y": 1, "w": 4, "h": 3, "base64": "data:image/png;base64,iVBOR...", "altText": "Logo" }
}
```

#### Table

```json
{
  "type": "table",
  "options": {},
  "tableOptions": {
    "x": 0.5, "y": 1.5, "w": 9, "h": 3,
    "border": { "pt": 1, "color": "E2E8F0" },
    "colW": [3, 3, 3],
    "fontSize": 12, "fontFace": "Arial"
  },
  "rows": [
    [
      { "text": "Name", "bold": true, "fill": { "color": "3B82F6" }, "color": "FFFFFF" },
      { "text": "Role", "bold": true, "fill": { "color": "3B82F6" }, "color": "FFFFFF" },
      { "text": "Status", "bold": true, "fill": { "color": "3B82F6" }, "color": "FFFFFF" }
    ],
    [
      { "text": "Alice" },
      { "text": "Engineer" },
      { "text": "Active" }
    ]
  ]
}
```

**Table cell properties:**

| Property | Type | Description |
|----------|------|-------------|
| `text` | string or text items | Cell content |
| `fill` | object | `{ "color": "hex" }` background |
| `color` | string | Text color (hex, no `#`) |
| `bold` | boolean | Bold text |
| `fontSize` | number | Font size |
| `fontFace` | string | Font family |
| `align` | string | `left`, `center`, `right` |
| `valign` | string | `top`, `middle`, `bottom` |
| `border` | object/array | Border definition |
| `colspan` | number | Columns to span |
| `rowspan` | number | Rows to span |
| `margin` | number/array | Cell margins |

#### Chart

```json
{
  "type": "chart",
  "options": {
    "x": 0.5, "y": 1.5, "w": 9, "h": 5,
    "chartType": "BAR",
    "showTitle": true,
    "title": "Revenue by Quarter",
    "showLegend": true,
    "legendPos": "b",
    "chartColors": ["3B82F6", "F97316", "9CA3AF"],
    "barDir": "col",
    "showValAxisTitle": true,
    "valAxisTitle": "Revenue ($M)",
    "data": [
      { "name": "Product A", "labels": ["Q1", "Q2", "Q3", "Q4"], "values": [1.2, 1.5, 1.8, 2.1] },
      { "name": "Product B", "labels": ["Q1", "Q2", "Q3", "Q4"], "values": [0.8, 0.9, 1.1, 1.3] }
    ]
  }
}
```

Chart types: `BAR`, `LINE`, `PIE`, `DOUGHNUT`, `SCATTER`, `BUBBLE`, `RADAR`, `AREA`.

**Chart options:**

| Property | Type | Description |
|----------|------|-------------|
| `chartType` | string | Chart type (see above) |
| `data` | array | `[{ name, labels, values }]` series data |
| `showTitle` | boolean | Show chart title |
| `title` | string | Chart title text |
| `showLegend` | boolean | Show legend |
| `legendPos` | string | Legend position: `b`, `t`, `l`, `r` |
| `chartColors` | string[] | Colors for each series (hex, no `#`) |
| `barDir` | string | Bar direction: `bar` (horizontal), `col` (vertical) |
| `barGrouping` | string | `clustered`, `stacked`, `percentStacked` |
| `showValue` | boolean | Show data values on chart |
| `showPercent` | boolean | Show percentages (pie/doughnut) |
| `showCatAxisTitle` | boolean | Show category axis title |
| `catAxisTitle` | string | Category axis title |
| `showValAxisTitle` | boolean | Show value axis title |
| `valAxisTitle` | string | Value axis title |
| `lineSize` | number | Line width (line charts) |
| `lineSmooth` | boolean | Smooth lines |

### Slide Masters

Define reusable backgrounds and placeholders:

```json
{
  "masters": [{
    "title": "BRANDED",
    "background": { "color": "0F172A" },
    "objects": [{ "text": { "text": "Company", "options": { "x": 0.5, "y": 6.8, "w": 3, "h": 0.5, "fontSize": 10, "color": "FFFFFF" } } }]
  }],
  "slides": [{
    "masterName": "BRANDED",
    "elements": [{ "type": "text", "options": { "x": 1, "y": 2, "w": 10, "h": 2, "text": "Title Slide", "fontSize": 36, "color": "FFFFFF" } }]
  }]
}
```

## Complete Example

```json
{
  "layout": "LAYOUT_WIDE",
  "author": "Analytics Team",
  "title": "Q1 2025 Performance",
  "slides": [
    {
      "background": { "color": "0F172A" },
      "elements": [
        { "type": "text", "options": { "x": 1, "y": 2.5, "w": 11, "h": 1.5, "text": "Q1 2025 Performance", "fontSize": 40, "fontFace": "Arial", "color": "FFFFFF", "bold": true, "align": "center" } },
        { "type": "text", "options": { "x": 1, "y": 4.2, "w": 11, "h": 0.8, "text": "Prepared by the Analytics Team", "fontSize": 20, "fontFace": "Arial", "color": "94A3B8", "align": "center" } }
      ]
    },
    {
      "elements": [
        { "type": "text", "options": { "x": 0.5, "y": 0.3, "w": 12, "h": 0.8, "text": "Revenue by Quarter", "fontSize": 28, "fontFace": "Arial", "bold": true, "color": "0F172A" } },
        {
          "type": "chart",
          "options": {
            "x": 0.5, "y": 1.5, "w": 12, "h": 5.5,
            "chartType": "BAR",
            "barDir": "col",
            "showTitle": false,
            "showLegend": true,
            "legendPos": "b",
            "chartColors": ["3B82F6", "F97316"],
            "data": [
              { "name": "Product A", "labels": ["Q1", "Q2", "Q3", "Q4"], "values": [1.2, 1.5, 1.8, 2.1] },
              { "name": "Product B", "labels": ["Q1", "Q2", "Q3", "Q4"], "values": [0.8, 0.9, 1.1, 1.3] }
            ]
          }
        }
      ]
    },
    {
      "elements": [
        { "type": "text", "options": { "x": 0.5, "y": 0.3, "w": 12, "h": 0.8, "text": "Key Metrics", "fontSize": 28, "fontFace": "Arial", "bold": true, "color": "0F172A" } },
        {
          "type": "table",
          "options": {},
          "tableOptions": { "x": 0.5, "y": 1.5, "w": 12, "border": { "pt": 1, "color": "E2E8F0" }, "colW": [4, 4, 4], "fontSize": 14, "fontFace": "Arial" },
          "rows": [
            [
              { "text": "Metric", "bold": true, "fill": { "color": "0F172A" }, "color": "FFFFFF" },
              { "text": "Actual", "bold": true, "fill": { "color": "0F172A" }, "color": "FFFFFF" },
              { "text": "Target", "bold": true, "fill": { "color": "0F172A" }, "color": "FFFFFF" }
            ],
            [{ "text": "Revenue" }, { "text": "$1.2M" }, { "text": "$1.1M" }],
            [{ "text": "New Customers" }, { "text": "340" }, { "text": "300" }],
            [{ "text": "Retention" }, { "text": "94%" }, { "text": "90%" }]
          ]
        }
      ],
      "notes": "Highlight that all KPIs exceeded targets this quarter."
    }
  ]
}
```

## Critical Rules

1. **Always write JSON to a temp file first** -- do NOT pass JSON inline to the command. Write the descriptor to a file, then reference it with `--input`.
2. **Use straight quotes in JSON** -- never use smart/curly quotes. Standard JSON double quotes only.
3. **Image paths must be absolute** -- or relative to the working directory where the command runs.
4. **All coordinates and sizes are in inches** -- `x: 0.5` means half an inch from the left edge.
5. **Colors are 6-char hex WITHOUT the `#` prefix** -- use `3B82F6` not `#3B82F6`.
6. **Use `LAYOUT_WIDE` for 16:9 presentations** -- default slide is 13.33" x 7.5".
7. **Chart data series must have matching `labels` and `values` array lengths.**

## Tips

- All coordinates and sizes are in **inches** (e.g., `x: 0.5` = half an inch from the left)
- For `LAYOUT_WIDE` (default): slide is 13.33" wide x 7.5" tall
- Use `items` array for multi-run text with mixed formatting within a single text box
- Use `slideNumber` on slides to add automatic slide numbers
- Use `notes` for speaker notes
- For charts, each data series needs `name`, `labels`, and `values` arrays of equal length
- Use `barDir: "col"` for vertical bars (column chart) and `barDir: "bar"` for horizontal bars

## Design guidance

Default pptxgenjs output often looks "AI-generated": flat colors, cramped text, accent lines under titles, and inconsistent spacing. Apply these rules to close that gap.

### Named palettes (hex, no `#`)

Pick ONE palette per deck and reuse its colors across every slide. Do not mix palettes.

| Palette | Background | Surface | Ink | Muted | Accent | Accent 2 |
|---------|-----------|---------|-----|-------|--------|----------|
| `midnight` | `0F172A` | `1E293B` | `F8FAFC` | `94A3B8` | `38BDF8` | `F472B6` |
| `paper` | `FFFFFF` | `F8FAFC` | `0F172A` | `64748B` | `2563EB` | `F97316` |
| `forest` | `0B3D2E` | `14532D` | `ECFDF5` | `86EFAC` | `FACC15` | `FB923C` |
| `sunset` | `1F1147` | `3B1F5A` | `FFF7ED` | `C4B5FD` | `FB7185` | `FDBA74` |
| `slate` | `F1F5F9` | `FFFFFF` | `0F172A` | `475569` | `0EA5E9` | `DC2626` |

### Typography stacks

- **Display / titles**: `Inter`, `Helvetica Neue`, or `Arial` — 36–44pt, `bold`
- **Body**: same family as titles — 18–22pt, regular
- **Caption / footnote**: 12–14pt, color = `Muted`
- **Avoid**: Comic Sans, Papyrus, Times New Roman for slide body
- **Rhythm**: title 40pt → subtitle 22pt → body 18pt → caption 12pt. Keep a consistent vertical rhythm across slides.

### Layout do / don't

Do:
- Leave ≥0.5" outer margin on every slide; content should never touch slide edges.
- Align elements to a consistent grid (multiples of 0.25").
- Use color to emphasize ONE item per slide — not three.
- Keep ≥36pt titles; ≥18pt body.
- Use whitespace generously — empty space is a design element.

Don't:
- Don't place an accent line directly under a title (dated "PowerPoint 2003" look).
- Don't stack more than ~7 bullets on a slide; split into multiple slides.
- Don't use drop shadows on text; reserve shadows for floating cards/shapes.
- Don't use low-contrast icon colors on colored backgrounds — check contrast ratio ≥3:1.
- Don't mix 3+ accent colors on a single slide.
- Don't leave default placeholder text ("Click to add title") — `render` will catch these.

### PPTX composition rules

- **Title block**: `{ x: 0.5, y: 0.3, w: 12.3, h: 0.9 }` for `LAYOUT_WIDE`.
- **Content block**: start at `y: 1.3`, leave `h` up to `~5.9` (slide is 7.5" tall minus footer).
- **Icon contrast**: use `Ink` color on `Background`, `Background` on `Accent`. Do not use `Accent` on `Accent 2`.
- **Tables**: header row uses `Accent` fill with `Background` text; alternate data rows with `Surface` fill for zebra striping.
- **Charts**: feed `chartColors` in palette order (`[Accent, Accent 2, Muted]`); do not rely on pptxgenjs defaults.
- **Shapes as cards**: `fill: Surface`, `line: { color: Muted, width: 0.5 }`, `rectRadius: 0.1`.

## Subagent patterns

Use subagents to parallelize work and to get "fresh eyes" on the rendered output.

### Pattern 1 — Parallel per-slide editing

Split one-deck work across N subagents. Each subagent owns a single slide via `{slide: N}` selectors, edits via `get` → mutate → `set`, and never reads or writes unrelated slides. This keeps each subagent's context small and prevents accidental regressions.

```bash
# Coordinator gets the outline
zenskill office presentation outline --input deck.pptx --output /tmp/outline.json

# Per-slide subagent: edit slide 3 only
zenskill office presentation get --selector "slide:3" --input deck.pptx --output /tmp/slide3.json
# ... subagent mutates /tmp/slide3.json ...
zenskill office presentation set --selector "slide:3" --content /tmp/slide3.json --input deck.pptx --output deck.pptx
```

Unaffected slides remain byte-identical (XML fast-path), so concurrent `set` calls against different slides compose safely. Serialize `set` calls against the SAME slide.

### Pattern 2 — Visual QA reviewer subagent (render → inspect → fix loop)

A JSON descriptor can be structurally perfect and still render with overlapping shapes, overflowing text, low-contrast icons, or leftover placeholders. ALWAYS run this loop before declaring a deck "done":

1. **Render**: emit a thumbnail grid of the full deck plus full-resolution images of each slide.
   ```bash
   zenskill office presentation render --input deck.pptx --thumbnail --output /tmp/deck-grid.png
   zenskill office presentation render --input deck.pptx --slides 1-10 --output /tmp/slides/
   ```
2. **Inspect**: spawn a *fresh* subagent with NO context about what the deck "should" look like. Feed it only the rendered images and this role prompt.
3. **Fix**: main agent reads the reviewer's report and issues targeted `set` calls per slide. Re-render. Repeat until the reviewer returns zero issues.

Limit the loop to 3 iterations; escalate to the user if issues persist.

#### Reviewer role prompt (paste-ready)

```
You are a slide-deck visual reviewer. You will see rendered PNG images of
slides from a PowerPoint deck. You have NO other context — judge ONLY what
you see.

For each slide, report issues in these categories:
  1. Overflow — text clipped or running off the slide
  2. Overlap — shapes or text boxes overlapping unintentionally
  3. Contrast — text or icons with contrast ratio <3:1 against background
  4. Placeholder — visible "Click to add title/text", lorem ipsum, TODOs
  5. Alignment — elements visibly off-grid or inconsistently placed across slides
  6. Typography — font size too small (<16pt body, <28pt title), inconsistent fonts
  7. Color — palette drift (>3 accent colors used), clashing colors
  8. Density — more than 7 bullets, wall of text, unreadable chart

Output strict JSON:
  { "slides": [ { "slide": 1, "issues": [ { "category": "Overlap", "detail": "Title overlaps chart top", "severity": "high" } ] } ] }

Report NO issues if the slide is clean. Be honest; do not hedge.
```

### Pattern 3 — Parallel layout generation

For multi-variant layout exploration, spawn N subagents that each produce a full descriptor for the same content. Render all variants with `--thumbnail`, show the grid to the user, pick a winner, discard the rest.

## Shared selector grammar

All new slice actions (`get`, `set`, `outline`) accept a `--selector` flag in either JSON or shorthand form.

| Format | JSON | Shorthand |
|--------|------|-----------|
| PPTX single slide | `{"slide": 3}` | `slide:3` |
| PPTX range | `{"slides": "2-5"}` | `slides:2-5` |
| PPTX list | `{"slides": [1,3,5]}` | `slides:1,3,5` |
| Any | `{"xpath": "//p:sld[1]//a:t[1]"}` | `xpath:…` |
| Any | `{"regex": "Revenue \\$\\d+"}` | `regex:…` |

Use `outline` first to discover valid selectors for the target deck.

## New actions

### Mutating actions write to `--output`

`set` and `write-part` always write the result to `--output`, leaving `--input` untouched. Pass a fresh path (e.g. `deck.edited.pptx`) — or the same path as `--input` if you explicitly want to overwrite. If a `set` produces invalid bytes the original is still safe at `--input`, so no separate backup step is required.

### `render` — rasterize slides to PNG

```bash
# Single slide → file
zenskill office presentation render --input deck.pptx --slide 3 --output slide3.png

# Range → directory (emits slide-01.png, slide-02.png, …)
zenskill office presentation render --input deck.pptx --slides 1-10 --output /tmp/slides/

# Thumbnail grid of the whole deck → single file
zenskill office presentation render --input deck.pptx --thumbnail --output deck-grid.png

# Custom resolution
zenskill office presentation render --input deck.pptx --slide 1 --dpi 200 --output slide1.png
```

| Flag | Notes |
|------|-------|
| `--slide N` / `--slides N-M` / `--slides 1,3,5` | Selection |
| `--thumbnail` | Compose grid of all selected slides into one image |
| `--dpi` | Default 144 |
| `--format` | `png` (default) |

Requires LibreOffice (`soffice`) on `$PATH` or `$ZENSKILL_SOFFICE_PATH`. Returns `VALIDATION_ERROR` with install hint if missing.

### `get` — extract a slice descriptor

```bash
zenskill office presentation get --selector "slide:3" --input deck.pptx --output slice.json
```

Returns a `PptxDescriptor` containing only the selected slide(s). Use for per-slide subagent editing without loading the whole deck.

### `set` — replace a slice

```bash
zenskill office presentation set --selector "slide:3" \
  --content slice.json --input deck.pptx --output deck.pptx
```

Writes the new slide descriptor to `--output`; unaffected slides stay byte-identical (XML fast-path). Use the same path as `--input` to overwrite, or a fresh path (e.g. `deck.edited.pptx`) to keep the original.

### `outline` — list all selectors

```bash
zenskill office presentation outline --input deck.pptx --output outline.json
```

Returns an `OutlineResult` with `{ selector: {slide: N}, label: "<slide title>", depth }` per slide.

### `list-parts` / `read-part` / `write-part` — XML escape hatch

For unsupported features (macros, tracked changes, equations, form fields, SmartArt) drop into XML mode *within zenskill* instead of reaching for python-pptx.

```bash
# List all internal OOXML parts
zenskill office presentation list-parts --input deck.pptx --output parts.json

# Dump a single part
zenskill office presentation read-part --input deck.pptx \
  --part "ppt/slides/slide1.xml" --output slide1.xml

# Write a part back (auto-maintains [Content_Types].xml and _rels/*)
zenskill office presentation write-part --input deck.pptx \
  --part "ppt/slides/slide1.xml" --content slide1.xml --output deck.pptx
```

`write-part` auto-registers new parts in `[Content_Types].xml` and the relevant `.rels` file when content type can be inferred from MIME or path prefix. Unknown types return `VALIDATION_ERROR`.

`write-part` writes the result to `--output` (use the same path as `--input` to overwrite) and writes raw OOXML without schema validation — malformed XML will only surface at render time, or worse, when PowerPoint refuses to open the file. Render the result before discarding the original.

#### Per-slide OOXML fallback (large decks)

PPTX is already split **per slide at the OOXML layer** — each slide is its own part at `ppt/slides/slideN.xml`. `read-part` and `write-part` therefore operate per-slide natively, so large decks don't require loading every slide into context:

```bash
# Read ONLY slide 17's XML — nothing else is touched.
zenskill office presentation read-part --input deck.pptx \
  --part "ppt/slides/slide17.xml" --output slide17.xml

# Replace ONLY slide 17's XML — every other part stays byte-identical.
zenskill office presentation write-part --input deck.pptx \
  --part "ppt/slides/slide17.xml" --content slide17.xml --output deck.pptx
```

For even finer granularity inside a single slide, layout, master, or theme part (e.g. when a slide's XML is very long and you only want one `<p:sp>`), pass `--selector regex:…` to scope the I/O to a sub-part slice. Only the first match is returned (on read) or replaced (on write); the rest of the part stays untouched:

```bash
zenskill office presentation read-part --input deck.pptx \
  --part "ppt/slides/slide17.xml" \
  --selector 'regex:<p:sp>[\s\S]*?<p:nvSpPr>[\s\S]*?name="Title 1"[\s\S]*?</p:sp>' \
  --output title-shape.xml

zenskill office presentation write-part --input deck.pptx \
  --part "ppt/slides/slide17.xml" \
  --selector 'regex:<p:sp>[\s\S]*?<p:nvSpPr>[\s\S]*?name="Title 1"[\s\S]*?</p:sp>' \
  --content title-shape.xml --output deck.pptx
```

Regex runs with the `s` flag. Use non-greedy quantifiers and anchor to stable tags (`<p:sp>`, `<p:sld>`, `<p:cSld>`). Structural selectors (`slide`, `heading`, `cell`, `xpath`, `page`) are rejected for sub-part slice I/O — use descriptor-level `get`/`set` for those.
