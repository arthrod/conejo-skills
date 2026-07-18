---
name: zen-office-xlsx
description: Create, read and edit professional Excel spreadsheets (.xlsx) using JSON descriptors via the zenskill CLI. Triggers when the user asks to create, generate, read, edit, modify, or write a spreadsheet, workbook, data table, or mentions .xlsx, Excel, or tabular data export.
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

# Spreadsheets (.xlsx)

Create and edit Excel spreadsheets (.xlsx) from a JSON descriptor via the `zenskill` CLI.

## When to Use

- User asks to create, generate, or write a spreadsheet, workbook, or data table
- User asks to edit, modify, or update an existing spreadsheet
- User mentions .xlsx, Excel, spreadsheet, workbook, or tabular data export
- You need to produce a downloadable/shareable spreadsheet (not just markdown or CSV)

## Quick Start

```bash
# 1. Write a JSON descriptor to a temp file
cat > /tmp/descriptor.json << 'ENDJSON'
{
  "sheets": [{
    "name": "Sales Data",
    "columns": [
      { "header": "Product", "key": "product", "width": 25 },
      { "header": "Revenue", "key": "revenue", "width": 15, "style": { "numFmt": "$#,##0.00" } }
    ],
    "rows": [
      ["Widget A", 4498.50],
      ["Widget B", 11497.70],
      ["Total", { "formula": "SUM(B2:B3)" }]
    ],
    "autoFilter": true,
    "freezeRow": 1
  }]
}
ENDJSON

# 2. Generate the .xlsx file
zenskill office spreadsheet create --input /tmp/descriptor.json --output /tmp/report.xlsx
```

## Commands

### Create a new spreadsheet

```
zenskill office spreadsheet create --input <json> --output <path>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--input` | Yes | Path to the JSON descriptor file |
| `--output` | Yes | Path for the generated .xlsx file (parent dirs created automatically) |

The command reads the JSON descriptor, builds the file, writes the output, and returns a JSON envelope with the output path.

### Read an existing spreadsheet

```
zenskill office spreadsheet read --input <xlsx> --output <json>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--input` | Yes | Path to the existing .xlsx file to read |
| `--output` | Yes | Path where the JSON descriptor will be written |

The command parses the .xlsx file and outputs its JSON descriptor. This descriptor uses the same format as the `create` command, enabling round-trip editing.

## Editing Workflow (Read → Modify → Create)

To edit an existing .xlsx file:

```bash
# 1. Read the existing spreadsheet into a JSON descriptor
zenskill office spreadsheet read --input /path/to/existing.xlsx --output /tmp/descriptor.json

# 2. Read and modify the JSON descriptor as needed
# (edit sheets, rows, columns, formulas, styles, etc.)

# 3. Create the updated spreadsheet from the modified descriptor
zenskill office spreadsheet create --input /tmp/descriptor.json --output /path/to/updated.xlsx
```

### Supported features for reading

- Multiple sheets with names and tab colors
- Columns with headers, widths, hidden state, and styles
- Rows with values, heights, hidden state, and styles
- Cell values (strings, numbers, booleans, dates)
- Formulas
- Cell styles (font, fill, alignment, border, numFmt)
- Merged cells
- Auto-filters
- Freeze panes
- Conditional formatting
- Data validations
- Sheet protection
- Page setup and margins
- Header/footer
- Hyperlinks
- Comments

### Unsupported features (will error on read)

Documents containing the following features cannot be read and will produce an error:

- VBA macros
- Pivot tables
- External data connections
- Sparklines
- Slicers
- Chart sheets

## Descriptor Format

The descriptor is a JSON object with this top-level structure:

```json
{
  "creator": "Author Name",
  "title": "Workbook Title",
  "subject": "Subject",
  "sheets": [ ... ]
}
```

Only `sheets` is required. Each sheet has a `name` and an array of `rows`.

### Sheets

```json
{
  "sheets": [{
    "name": "Sales Data",
    "tabColor": "FF3B82F6",
    "columns": [
      { "header": "Product", "key": "product", "width": 25 },
      { "header": "Revenue", "key": "revenue", "width": 15, "style": { "numFmt": "$#,##0.00" } }
    ],
    "rows": [ ... ],
    "merges": ["A1:C1"],
    "autoFilter": true,
    "freezeRow": 1,
    "styles": { "headerStyle": { "font": { "bold": true, "color": "FFFFFF" }, "fill": { "fgColor": "FF3B82F6" } } }
  }]
}
```

### Row Formats

**Simple array rows** (values by position):
```json
{ "rows": [
  ["Product A", 1200, 15.5, true],
  ["Product B", 800, 10.2, false]
] }
```

**Array rows with formulas:**
```json
{ "rows": [
  ["Product A", 1200, 800, { "formula": "B2-C2" }],
  ["Product A", 1500, 900, { "formula": "B3-C3" }],
  ["Total", { "formula": "SUM(B2:B3)" }, { "formula": "SUM(C2:C3)" }, { "formula": "SUM(D2:D3)" }]
] }
```

**Rich row objects** (with height, visibility, styles):
```json
{
  "values": ["Product A", 1200, 15.5],
  "height": 25,
  "style": { "font": { "bold": true } }
}
```

**Rich cell objects** (cell-level control):
```json
{
  "cells": {
    "A": { "value": "Product A", "style": { "font": { "bold": true } } },
    "B": { "value": 1200, "style": { "numFmt": "$#,##0.00" } },
    "C": { "formula": "B1*1.1", "style": { "numFmt": "$#,##0.00" } },
    "D": { "value": "Click here", "hyperlink": "https://example.com" }
  }
}
```

### Cell Styles

```json
{
  "font": {
    "name": "Arial",
    "size": 12,
    "bold": true,
    "italic": false,
    "underline": false,
    "strike": false,
    "color": "FF334155"
  },
  "fill": {
    "type": "pattern",
    "pattern": "solid",
    "fgColor": "FFDBEAFE"
  },
  "alignment": {
    "horizontal": "center",
    "vertical": "middle",
    "wrapText": true,
    "textRotation": 0,
    "indent": 0
  },
  "border": {
    "top": { "style": "thin", "color": "FF000000" },
    "bottom": { "style": "thin", "color": "FF000000" },
    "left": { "style": "thin", "color": "FF000000" },
    "right": { "style": "thin", "color": "FF000000" }
  },
  "numFmt": "$#,##0.00"
}
```

**Colors** use ARGB format (8-char hex): `FF3B82F6` where `FF` is the alpha channel.

**Border styles:** `thin`, `medium`, `thick`, `dotted`, `dashed`, `double`.

**Number formats:**

| Format String | Example Output |
|---------------|----------------|
| `$#,##0.00` | $1,234.56 |
| `#,##0` | 1,235 |
| `0.00%` | 15.50% |
| `yyyy-mm-dd` | 2025-03-30 |
| `mm/dd/yyyy` | 03/30/2025 |
| `0.00` | 15.50 |

### Sheet Features

**Auto-filter:**
```json
{ "autoFilter": true }
```
Or specify a range: `{ "autoFilter": "A1:D10" }`

**Freeze panes:**
```json
{ "freezeRow": 1 }
```
Or: `{ "freezePane": { "row": 1, "column": 1 } }`

**Page setup:**
```json
{
  "pageSetup": {
    "orientation": "landscape",
    "paperSize": 9,
    "fitToPage": true,
    "fitToWidth": 1,
    "fitToHeight": 0,
    "margins": { "top": 0.75, "bottom": 0.75, "left": 0.7, "right": 0.7 }
  }
}
```

Paper sizes: 9 = A4, 1 = Letter.

**Header/footer:**
```json
{ "headerFooter": { "oddHeader": "&C&\"Arial,Bold\"Monthly Report", "oddFooter": "&CPage &P of &N" } }
```

**Conditional formatting:**
```json
{
  "conditionalFormatting": [{
    "ref": "B2:B100",
    "rules": [{
      "type": "cellIs",
      "operator": "greaterThan",
      "formulae": ["1000"],
      "style": { "font": { "color": "FF15803D" }, "fill": { "fgColor": "FFDCFCE7" } },
      "priority": 1
    }]
  }]
}
```

**Data validations:**
```json
{
  "dataValidations": [{
    "ref": "C2:C100",
    "type": "list",
    "formulae": ["\"Active,Inactive,Pending\""],
    "showErrorMessage": true,
    "errorTitle": "Invalid",
    "error": "Please select from the list"
  }]
}
```

**Sheet protection:**
```json
{ "protection": { "password": "secret", "sheet": true } }
```

## Complete Example

```json
{
  "creator": "Sales Team",
  "title": "Q1 Sales Report",
  "sheets": [
    {
      "name": "Sales Data",
      "tabColor": "FF3B82F6",
      "columns": [
        { "header": "Product", "key": "product", "width": 25 },
        { "header": "Units Sold", "key": "units", "width": 15 },
        { "header": "Unit Price", "key": "price", "width": 15, "style": { "numFmt": "$#,##0.00" } },
        { "header": "Revenue", "key": "revenue", "width": 18, "style": { "numFmt": "$#,##0.00" } }
      ],
      "rows": [
        ["Widget A", 150, 29.99, { "formula": "B2*C2" }],
        ["Widget B", 230, 49.99, { "formula": "B3*C3" }],
        ["Widget C", 89, 99.99, { "formula": "B4*C4" }],
        ["Total", { "formula": "SUM(B2:B4)" }, null, { "formula": "SUM(D2:D4)" }]
      ],
      "autoFilter": "A1:D1",
      "freezeRow": 1,
      "styles": {
        "headerStyle": {
          "font": { "bold": true, "color": "FFFFFFFF" },
          "fill": { "fgColor": "FF3B82F6" },
          "alignment": { "horizontal": "center" }
        }
      },
      "conditionalFormatting": [{
        "ref": "D2:D4",
        "rules": [{
          "type": "cellIs",
          "operator": "greaterThan",
          "formulae": ["5000"],
          "style": { "font": { "color": "FF15803D" }, "fill": { "fgColor": "FFDCFCE7" } },
          "priority": 1
        }]
      }]
    },
    {
      "name": "Summary",
      "rows": [
        [{ "value": "Q1 2025 Sales Summary", "formula": null }],
        [],
        ["Total Products", 3],
        ["Total Revenue", { "formula": "'Sales Data'!D5" }]
      ]
    }
  ]
}
```

## Critical Rules

1. **Always write JSON to a temp file first** -- do NOT pass JSON inline to the command. Write the descriptor to a file, then reference it with `--input`.
2. **Use straight quotes in JSON** -- never use smart/curly quotes. Standard JSON double quotes only.
3. **Colors use ARGB format (8-char hex)** -- use `FF3B82F6` where `FF` is the alpha channel (always `FF` for opaque).
4. **Formulas do NOT start with `=`** -- use `"formula": "SUM(A1:A10)"` not `"formula": "=SUM(A1:A10)"`.
5. **Sheet names must be unique and <=31 characters.**
6. **`autoFilter: true` auto-calculates the range** -- or pass an explicit range string like `"A1:D10"`.

## Tips

- Use `columns` with `header` to define column headers and widths -- the first data row added will be headers
- Use `{ "formula": "..." }` in array rows for Excel formulas; formulas do NOT start with `=`
- Use `autoFilter: true` for automatic filter on all columns, or a range string for specific columns
- `freezeRow: 1` freezes the header row so it stays visible when scrolling
- Use `numFmt` in cell/column styles for number formatting (currency, percentage, dates)
- For cross-sheet references in formulas, use `'Sheet Name'!A1` syntax

## Design guidance

### Named palettes (ARGB, 8-char hex)

Pick ONE palette per workbook and reuse for headers, banding, and conditional formatting.

| Palette | Header fill | Header text | Band A | Band B | Positive | Negative |
|---------|-------------|-------------|--------|--------|----------|----------|
| `paper` | `FF2563EB` | `FFFFFFFF` | `FFF1F5F9` | `FFFFFFFF` | `FF15803D` | `FFDC2626` |
| `midnight` | `FF0F172A` | `FFF8FAFC` | `FF1E293B` | `FF334155` | `FF22D3EE` | `FFF472B6` |
| `forest` | `FF14532D` | `FFECFDF5` | `FFF0FDF4` | `FFFFFFFF` | `FF16A34A` | `FFB91C1C` |
| `corporate` | `FF1E3A8A` | `FFFFFFFF` | `FFEFF6FF` | `FFFFFFFF` | `FF047857` | `FFB91C1C` |
| `mono` | `FF18181B` | `FFFAFAFA` | `FFF4F4F5` | `FFFFFFFF` | `FF000000` | `FFDC2626` |

### Numeric formatting rules

Consistent number formats are the single biggest readability win for spreadsheets. Apply at the *column* level via `columns[].style.numFmt`, not per-cell.

| Data kind | `numFmt` | Notes |
|-----------|----------|-------|
| Currency (USD) | `$#,##0.00` | Negative: `$#,##0.00;[Red]-$#,##0.00` for accounting |
| Whole currency | `$#,##0` | Drop decimals for totals and summaries |
| Percent | `0.00%` | Store as 0.15 for 15%, never multiply |
| Integer count | `#,##0` | Always thousands separator for counts >999 |
| Ratio | `0.00` | |
| Date | `yyyy-mm-dd` | ISO — sorts correctly; avoid locale-specific formats |
| Date-time | `yyyy-mm-dd hh:mm` | |
| Duration (hours) | `[h]:mm` | `[h]` lets hours exceed 24 |

Always right-align numeric columns (`alignment: { horizontal: "right" }`); left-align text columns.

### Typography

- **Default font**: `Calibri` or `Arial`, size 11. Don't mix families.
- **Headers**: bold, same size as body. Use background fill for emphasis, not font size.
- **Monospace** (IDs, codes, JSON cells): `Consolas` or `Courier New`, size 10.
- Row height: default (15) for data; 24–28 for header row to provide breathing room.

### Layout rules

Do:
- Freeze the header row: `freezeRow: 1`.
- Enable auto-filter on data ranges.
- Use `conditionalFormatting` for highlights; don't manually color cells.
- Use zebra striping (alternating `Band A` / `Band B`) for tables >10 rows.
- Round column widths: `width: 15` / `20` / `25` — not `23.7`.

Don't:
- Don't use multi-level headers with merged cells (breaks filters, sorts, pivot tables).
- Don't leave a single sheet called `Sheet1` — always name sheets descriptively (≤31 chars).
- Don't bold every row; reserve bold for headers and totals.
- Don't use borders on every cell — use subtle top/bottom borders on header and total rows only.

## Subagent patterns

For parallel editing (per-sheet) and visual QA patterns, see the reviewer role prompt and render → inspect → fix loop in [SKILL-PPTX.md](./SKILL-PPTX.md#subagent-patterns). Spreadsheets do not support `render` in this release; instead, a QA subagent can audit the JSON descriptor against the "Design guidance" checklist above (consistent `numFmt` per column, header styling, freeze/filter presence, palette drift).

## Shared selector grammar

All new slice actions (`get`, `set`, `outline`) accept a `--selector` flag in either JSON or shorthand form.

| Form | JSON | Shorthand |
|------|------|-----------|
| Single cell | `{"cell": "Sheet1!B5"}` | `cell:Sheet1!B5` |
| Range | `{"range": "Sheet1!A1:C10"}` | `range:Sheet1!A1:C10` |
| Whole sheet | `{"sheet": "Sheet1"}` | `sheet:Sheet1` |
| XPath over sheet XML | `{"xpath": "//c[@r='B5']"}` | `xpath:…` |

Use `outline` to list sheets and named ranges.

## New actions

### Mutating actions write to `--output`

`set` and `write-part` always write the result to `--output`, leaving `--input` untouched. Pass a fresh path (e.g. `book.edited.xlsx`) — or the same path as `--input` if you explicitly want to overwrite. If a `set` produces invalid bytes (formulas, named ranges, or conditional formatting silently dropped) the original is still safe at `--input`, so no separate backup step is required.

### `get` — extract a slice

```bash
zenskill office spreadsheet get --selector "cell:Sheet1!B5" \
  --input book.xlsx --output cell.json

zenskill office spreadsheet get --selector "range:Sheet1!A1:C10" \
  --input book.xlsx --output slice.json

zenskill office spreadsheet get --selector "sheet:Summary" \
  --input book.xlsx --output summary.json
```

### `set` — write a slice

```bash
zenskill office spreadsheet set --selector "range:Sheet1!A1:C10" \
  --content slice.json --input book.xlsx --output book.xlsx
```

Non-targeted sheets and cells remain byte-identical. The result is written to `--output` — pass the same path as `--input` to overwrite, or a fresh path (e.g. `book.edited.xlsx`) to keep the original.

### `outline` — list sheets and named ranges

```bash
zenskill office spreadsheet outline --input book.xlsx --output outline.json
```

### `list-parts` / `read-part` / `write-part` — XML escape hatch

For unsupported features (pivot tables, external connections, slicers) drop into XML mode *within zenskill*:

```bash
zenskill office spreadsheet list-parts --input book.xlsx --output parts.json
zenskill office spreadsheet read-part --input book.xlsx \
  --part "xl/worksheets/sheet1.xml" --output sheet1.xml
zenskill office spreadsheet write-part --input book.xlsx \
  --part "xl/worksheets/sheet1.xml" --content sheet1.xml --output book.xlsx
```

`write-part` auto-maintains `[Content_Types].xml` and `_rels/*` for new parts.

`write-part` writes the result to `--output` (use the same path as `--input` to overwrite) and writes raw OOXML without schema validation — malformed XML will only surface when the workbook is re-opened, or worse, when Excel refuses to open it. Re-open / re-render the result before discarding the original.

#### Per-sheet OOXML fallback (large workbooks)

Like PPTX slides, XLSX stores each worksheet as its own OOXML part (`xl/worksheets/sheetN.xml`), so `read-part` / `write-part` are already per-sheet at the XML layer. For bigger sheets (or the shared strings / styles parts) pass `--selector regex:…` to scope the I/O to a sub-part slice. Only the first match is returned (on read) or replaced (on write); every other byte of the part and every other part in the archive stay identical.

```bash
zenskill office spreadsheet read-part --input book.xlsx \
  --part "xl/worksheets/sheet1.xml" \
  --selector 'regex:<row r="5"\b[\s\S]*?</row>' \
  --output row5.xml
```

Regex runs with the `s` flag. Structural selectors (`cell`, `range`, `sheet`, `xpath`, `heading`, `slide`, `page`) are rejected for sub-part slice I/O — use descriptor-level `get`/`set` for those.
