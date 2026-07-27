# Conejo-Legal — Reference

Heavy reference for the conejo-legal skill: runtime context, input shapes, file templates, search planning, source frameworks, and style rules. Read the section you need when the corresponding workflow step calls for it.

---

## Runtime Context (pydantic-researchers)

The workflow may use these features:

1. `report_type="deep_research"`: an orchestrator creates an outline and SERP queries, then dispatches recursive branch researchers.
2. `ResearchPlan`: structured outline plus initial search queries.
3. `BranchFindings`: per-branch learnings and follow-up questions.
4. `DeepResearchResult`: aggregate outline, learnings, citations, visited URLs, branches, cost, timing, and retained `source_documents`.
5. `ResearchPackage`: optional multi-file and source-retention configuration.
6. `return_sources=True`: retain full source documents and render OKF source Markdown deterministically.
7. `additional_urls`: fetch and retain URLs not discovered through search. The runner pre-probes primary-law APIs (CourtListener, GovInfo, eCFR) and injects candidates as `injected_primary_sources`. Treat them as high-priority candidate evidence: read and use when relevant, discard when not — never cite one you did not read, never assume primary authority exists just because a candidate was injected.
8. `synthesis_mode="single" | "split" | "sections"`: one report, per-source companion reports, or per-section companion reports.
9. MCP presets or configs may replace normal retrievers. Treat MCP output as source evidence; never invent missing results.

The workflow may branch, recurse, compress context, and degrade gracefully when optional fetches fail. Your file outputs must remain deterministic from the evidence actually returned.

### Runner coordination

- Use injected candidate URLs when relevant; injected ≠ relevant.
- Never cite uninspected injected material.
- Retain source bodies deterministically when configured.
- Leave runner-owned files (`caselaw_index.md`, `statutory_index.md`) to the runner. Skeletons created at materialization time are overwritten by the runner after your run.
- `run.json` is runner-owned in existence, append-only in content: never create it, never rewrite it, but IF it already exists THEN append this run's terminal-decision record to it (Step 9 — see [Run State File](#run-state-file-runjson) below). The runner may still rewrite the file after your run; that is why the same decision text is also written into the audit, which is yours.

### Injected primary sources protocol

For each `injected_primary_sources` URL: (1) attempt fetch/inspect; (2) classify `accepted` / `rejected` / `lead_only` / `conversion_failed` / irrelevant; (3) if accepted, retain and cite only what you read; (4) if irrelevant, say so in the audit; (5) never invent holdings from the URL string alone.

---

## Inputs

### topic_or_query

Authoritative. Possible shapes: (1) a plain query string; (2) a JSON list of hierarchy levels, final item = topic leaf; (3) a structured object with `query`, `topic_hierarchy`, `output_root`, `topic_directory`, `research_package`, and optional file templates.

Do not call `key_digest/get_topic.py` unless the runtime explicitly says this is a legacy key_digest run.

### path_values

Use supplied path values; if absent, derive deterministically.

- Bundle root: `american_legal_digest/okf`
- Topic directory: `{{BUNDLE_ROOT}}/{{NORMALIZED_LEVEL_1}}/.../{{NORMALIZED_TOPIC_LEAF}}`
- Main digest: `{{TOPIC_DIRECTORY}}/{{NORMALIZED_TOPIC_LEAF}}.md`
- Audit: `{{TOPIC_DIRECTORY}}/_source_snippet_audit.md`
- Retained sources: `{{TOPIC_DIRECTORY}}/sources/{{SOURCE_SLUG}}.md`
- Optional: `report.md`, `reports/sources/{{SOURCE_SLUG}}.md`, `reports/sections/{{NN}}-{{SECTION_SLUG}}.md`

If the main digest and synthesized report are the same artifact in the calling workflow, write only the main digest and report that `report.md` was not a separate output.

### normalization

Unless the runtime gives an explicit slug:

1. Replace every character not matching `[a-zA-Z0-9.&§]` with `_`.
2. Collapse repeated underscores; strip leading/trailing underscores.
3. If the normalized name is `index` (case-insensitive), rename to `index_`.
4. If normalization produces an empty string, preserve the original name.

Companion report slugs: lowercase, non-alphanumeric runs → hyphens, collapse repeats, trim.

### jurisdiction

Default: United States federal law. Switch explicitly when input or sources clearly indicate otherwise; say so in digest and audit; avoid mixing jurisdictions casually; explain federal/state interaction when it matters; never import federal terminology into state doctrine without support.

For old, obsolete, or archaic topics: identify current terminology and modern treatment. Preserve historical framing, but never present obsolete terminology as the modern doctrinal category unless that is accurate. Historical labels: keep them when they matter to source discovery; check whether the label remains searchable in current cases and whether modern sources use a different umbrella term.

---

## File Templates

Templates are part of the skill contract. Some may be supplied frontmatter-only — that is valid input, never a failure signal.

### folder_index_template

For `index.md` navigation files only. Body may be empty; do not replace with digest frontmatter.

```markdown
***
okf_version: "0.1"
***
```

### main_digest_template

For `{{TOPIC_DIRECTORY}}/{{NORMALIZED_TOPIC_LEAF}}.md`. MUST be a SKOS-compatible OKF legal issue (not a bare `type: digest` stub):

```markdown
***
okf_version: "0.1"
type: legal_issue

id: "urn:legal-taxonomy:issue:{{NOTATION}}"
notation: "{{NOTATION}}"

title: "{{TOPIC_LEAF_TITLE}}"
pref_label: "{{TOPIC_LEAF_TITLE}}"
alt_labels: []
historical_labels: []

description: ""
definition: ""
scope_note: ""
do_not_use_for: []

scheme: "Open Legal Issue Taxonomy"
status: "active"

broader:
  - "urn:legal-taxonomy:issue:{{PARENT_NOTATION}}"
narrower: []
related: []

legal_relations:
  defenseTo: []
  remedyFor: []
  procedureFor: []

facets_allowed: []

mappings:
  west_1914:
    closeMatch: []
  folio:
    closeMatch: []
    relatedMatch: []
  sali_lmss:
    broadMatch: []
  list:
    relatedMatch: []
  eurovoc:
    relatedMatch: []

version: "0.1.0"
created: "{{YYYY-MM-DD}}"
modified: "{{YYYY-MM-DD}}"
***
```

SKOS fill rules:

1. Keep `okf_version: "0.1"`, `type: legal_issue`, `scheme: "Open Legal Issue Taxonomy"`.
2. `notation` = dotted UPPER_SNAKE of the FOLIO-base path segments (e.g. `CONTRACT_LAW.FORMATION.CAPACITY.MINORS`). Derive from runtime `areas_of_law_path` / `topic_hierarchy`; do not invent a different hierarchy.
3. `id` MUST be `urn:legal-taxonomy:issue:{{notation}}` (exact match).
4. `pref_label` / `title` = human issue label (Bluebook-style leaf).
5. Fill `description` (one-sentence use-when), `definition` (what the issue is), `scope_note` (when to use it), `do_not_use_for` (clear out-of-scope topics).
6. `alt_labels` / `historical_labels` hold synonyms and obsolete terms found in research (empty lists valid).
7. `broader` = parent path URN (one hop up). Leave `narrower` empty unless the runtime supplies children. `related` only with path/evidence basis — never invent cross-links.
8. Soft FOLIO anchors: real FOLIO IRIs → `mappings.folio.closeMatch`; `x-digest:` soft refs → `mappings.folio.relatedMatch`. Other mapping blocks only where actual evidence exists — silence beats fabricated interoperability.
9. Provenance keys the runner may stamp (`issue_id`, `objectives_path`, `items`, `source_profile`, `timestamp`) are allowed after the SKOS block; do not remove.

SKOS (Simple Knowledge Organization System) is how FOLIO represents taxonomies: preferred/alternative labels, broader/narrower hierarchies, related associations, definition/scope notes, and cross-standard mappings. See the project doc `docs/FOLIO_SKOS.md` and FOLIO's "What is SKOS?" (https://folio.openlegalstandard.org/docs/what-is-skos).

**Leaving evidence-supported SKOS fields empty is a quality-control failure.** Structural humility: prefer the smaller, correct taxonomy statement — better `related` empty than invented; better "functions as a sub-issue of X" than a manufactured independent category.

### legal_relations

`defenseTo`: issue is a defense to a distinct claim or charge. `remedyFor`: issue functions primarily as a remedial concept. `procedureFor`: issue is primarily procedural relative to another substantive issue. Never fill as taxonomy decoration — evidentiary basis and path logic required.

### source_file_template

For each retained source under `sources/{{SOURCE_SLUG}}.md`:

```markdown
***
type: "source"
title: "{{SOURCE_FILENAME}}"
description: "{{SOURCE_TITLE}}"
resource: "{{SOURCE_URL}}"
tags: [{{SERP_QUERIES_OR_SOURCE_TAGS}}]
timestamp: "{{ISO_8601_UTC_TIMESTAMP}}"
***

{{MECHANICALLY_PRESERVED_SOURCE_MARKDOWN}}
```

The body must be mechanically preserved (HTML→Markdown conversion, public PDF text extraction, plus the frontmatter — nothing else). Never summarize, annotate, rewrite, correct, modernize, or clean up.

### source_snippet_audit_template

```markdown
***
type: "source_snippet_audit"
title: "{{TOPIC_LEAF_TITLE}} - Source and Snippet Audit"
description: "Search log, source-selection record, and factual source-supported snippets used and not used to build the digest."
resource: "{{TOPIC_DIRECTORY}}/{{NORMALIZED_TOPIC_LEAF}}.md"
tags: [sources, snippets, audit]
timestamp: "{{ISO_8601_UTC_TIMESTAMP}}"
***

## Terminal Decision

**Final state:** {{MERGED | CLOSED — <specific reason>}}
**Run state file:** {{path appended to | "absent — no run state file found" | "present but not appended: <exact reason>"}}

{{TERMINAL_DECISION_MESSAGE_VERBATIM}}
```

The `## Terminal Decision` section is required in every audit, MERGE and CLOSE alike, and comes first in the body — the audit is the copy of the record that survives a runner rewrite. Its message text must be byte-identical to the `github_message` value in the appended run record.

---

## Run State File (`run.json`)

Step 9. The runner owns this file; you may only ever add to the end of it.

### Discovery

Look for `run.json` in the topic directory, then the bundle root, then the output root. Accept an equivalently-named run state file — `run_state.json`, `runs.json`, `_run.json`, `run.jsonl` — when the runtime clearly uses one instead. IF nothing is found THEN do not create anything; record `absent` in the audit and stop at the audit copy.

### Inspect before you write

1. Read the **whole** file into memory and keep those original bytes until verification passes.
2. Parse it. Learn the existing top-level keys, the entry shape of any history array, key naming style, indentation, and whether the file ends with a newline.
3. IF parsing fails, the file is truncated, or the shape is one you cannot extend without guessing THEN touch nothing and log the exact reason: `run.json present at <path> but unparseable (<exact error>) — decision record kept in audit only.`

Never open the file in truncating write mode before the old content is parsed and held.

### Append algorithm

1. **Pick the history target.** IF an existing array already holds run records (`conejo_legal_runs`, `runs`, `history`, `events`) THEN append to that array, matching its key naming rather than fighting it. IF none exists THEN add a new top-level `conejo_legal_runs` array alongside the runner's keys — a new key, never a replacement for one.
2. **Append. Only append.** Add exactly one record at the end. Do not modify, reorder, renumber, reformat, re-indent, deduplicate, or delete any existing key or entry — including records your own earlier runs appended.
3. **Resumes and re-runs append too.** A run that supersedes an earlier record adds a new record carrying `supersedes: "<prior run_id>"`. The prior record stays exactly as it is, wrong terminal state and all — superseded history is history.
4. **JSONL:** append one record as a single line, terminated with a newline. No rewrite of prior lines.
5. **Write atomically:** serialize with the file's existing indentation (2-space default), write to a temp file in the same directory, then rename over the original. Preserve the trailing-newline convention.
6. **Verify, then report.** Re-read the file: your record must be present, and every pre-existing top-level key and entry must survive unchanged. IF anything else moved THEN restore the original bytes you held and log the failure instead. Report the path in the build report.

### Record schema

Include what you can support from the audit; omit fields the runtime never supplied rather than inventing them. Timestamps come from the real clock.

```json
{
  "skill": "conejo-legal",
  "run_id": "{{RUNNER_RUN_ID_OR_AUDIT_TIMESTAMP}}",
  "supersedes": null,
  "timestamp": "{{ISO_8601_UTC}}",
  "issue_id": "urn:legal-taxonomy:issue:{{NOTATION}}",
  "notation": "{{NOTATION}}",
  "topic_directory": "{{TOPIC_DIRECTORY}}",
  "terminal_state": "MERGED",
  "reason": "{{ONE SENTENCE — the operative why}}",
  "reason_detail": ["{{evidence-level bullets, same content as the message}}"],
  "gate": {
    "items_total": 20,
    "items_passed": 20,
    "failed_then_fixed": [{"item": 5, "what": "{{failure}}", "fix": "{{what changed}}"}],
    "failed_unfixable": []
  },
  "ledger": {"total": 34, "accepted": 26, "rejected": 5, "open": 2, "duplicate": 1, "reconciles": true},
  "sources": {"accepted": 14, "rejected": 6, "lead_only": 3, "retained_but_unused": 2, "conversion_failed": 1},
  "searches": 13,
  "files_written": ["{{paths}}"],
  "github_message": "{{TERMINAL_DECISION_MESSAGE_VERBATIM}}"
}
```

CLOSE records use the same schema with `terminal_state: "CLOSED"`, the unfixable item in `gate.failed_unfixable`, and a `reopen_when` field naming the condition that would change the outcome. `reason` is never `"gate failed"` or `"could not complete"` — name the item, the searches, and the missing authority.

---

## Terminal Decision Message (GitHub format)

Step 9. One message, written once, repeated verbatim in the run record's `github_message`, the audit's `## Terminal Decision` section, and the build report. Post it with `gh pr comment <NUMBER> -R <owner>/<repo> --body-file <file>` **only** when the runtime or user supplied a real PR or issue; otherwise the text itself is the deliverable.

Style: GitHub-flavored markdown, state-change voice, ≤ ~200 words. Bold state first, then one reason sentence, then evidence bullets with numbers and gate item references. Never "thanks", never apology, never a reason the audit cannot defend, never a count you did not compute.

### MERGED

```markdown
**Merged** — `CONTRACT_LAW.FORMATION.CAPACITY.MINORS`

Merge gate 20/20. Ledger reconciles: 34 material subquestions = 26 accepted + 5 rejected + 2 open + 1 duplicate.

**Why merged:** every digest proposition traces to an inspected free public source, and the two remaining gaps ship as `open` rather than smoothed into prose.

- 13 documented searches; contrary-authority and terminology passes both run.
- Sources: 14 accepted, 6 rejected, 3 lead-only, 1 conversion failure (CourtListener PDF extraction) — all preserved in the audit.
- Fixed before merge: gate item 5 — one learning carried a snippet-only URL; replaced with inspected statute text at `sources/uscode-...md`, proposition re-verdicted, ledger re-reconciled.

Bundle: `.../minors.md` · Audit: `.../_source_snippet_audit.md`
```

### CLOSED

```markdown
**Closed** — `{{NOTATION}}` — no accessible free public authority for the core issue.

**Why closed:** gate item 11 cannot pass in this run — every candidate stating the operative test is paywalled, and the free repositories return nothing for the exact issue or its two historical labels. Not fixable by more effort inside this run.

- 12 documented searches across CourtListener, GovInfo, eCFR, Cornell LII, and CRS — queries and empty results logged in the audit.
- Ledger: 18 = 0 accepted + 4 rejected + 14 open.
- Preserved: the audit at `.../_source_snippet_audit.md` and 2 retained sources.
- Reopen when: the opinion enters a free repository, or a public agency version of the operative text becomes retrievable.

A closed PR keeps its history; this closed run keeps its audit.
```

---

## Search Plan

Structured outline of 4–8 sections. Standard outline:

1. Issue framing and terminology. 2. Governing authority and legal framework. 3. Leading authorities and doctrinal test. 4. Current treatment and applications. 5. Contrary or limiting views. 6. Recent developments. 7. Practical significance. 8. Open questions and related concepts.

Query families: exact issue name, close synonyms, historical labels, statute/regulation identifiers, leading case names, agency names, constitutional clauses, limiting doctrines, recent developments, public practical explainers.

Document queries in the audit. **Target ≥10 distinct searches** unless the runtime was constrained or failures are recorded. A "search" is a distinct query or retrieval attempt, not vague browsing.

Strong public-source families: Congress.gov, GovInfo, eCFR, Supreme Court opinions, CourtListener, Cornell LII, Constitution Annotated, CRS reports, GAO materials, official agency and executive pages. Free repositories still need careful inspection — metadata quality varies.

### Question patterns (Step 1 ledger seeds)

Is the issue currently recognized as a distinct doctrine? What exact sources govern it? Is it constitutional, statutory, regulatory, structural, procedural, remedial, or hybrid? Controlling test? Elements? Exceptions? Burdens? Limiting principles? Is there a split? A terminology shift? Does the issue persist mainly as historical framing? Which practical actors care? Adjacent misclassifications? Does modern doctrine absorb the older category? Which sources best define the issue for taxonomy purposes?

### Outline → digest heading mapping

- framing/terminology → Overview + Current Terminology and Modern Treatment
- governing authority → Governing Framework + Constitutional, Statutory, or Structural Principles
- leading cases/tests → Leading Authorities + Current Doctrine
- contrary views → Contrary, Limiting, and Competing Views
- recent → Recent Developments
- practical → Practical Significance
- open/related → Open Questions and Contested Issues + Related Concepts
- all supported claims → Citations

Never reorder the required digest headings.

---

## Source Categorization

Every inspected source gets exactly one bucket:

| Bucket | Use when |
|---|---|
| `accepted` | Inspected, public, materially supports one or more digest propositions |
| `rejected` | Irrelevant, inaccessible, duplicative-and-inferior, outdated for the proposition, too weak/vague, paywalled, or snippet-only |
| `lead_only` | Led to better authority but not itself citable |
| `retained_but_unused` | Retained and inspected, but no final digest sentence relies on it (still useful for runner indexes and breadth) |
| `conversion_failed` | Would matter, but mechanical retention failed — log the exact failure mode |

Accepted-note style: `Accepted: official statute text defines operative terms used in Governing Framework.` / `Accepted: Supreme Court opinion provides controlling statement of standard.` / `Accepted: public law-firm alert used only in Recent Developments and Practical Significance.`

Rejected-note style: `Rejected: article paraphrases doctrine too generally and omits limiting language.` / `Rejected: paywalled source not inspected.` / `Rejected: duplicative of official source without added value.` / `Rejected: page inaccessible during run.`

### Retention rules (`return_sources=True`)

Retain when a source directly supports a digest sentence, illuminates contrary/limiting authority, establishes modern terminology, supplies recent developments, contributes important primary text, or matters to case/statutory indexes. Do not retain junk to inflate counts; do not skip relevant sources to keep the folder tidy; never retain inaccessible, fully superseded lead-only, duplicate, irrelevant, or paywalled material.

---

## Contradiction Handling

When sources conflict, do not flatten the conflict into mush:

1. Identify each source's authority rank.
2. Determine whether the conflict is real or only apparent.
3. Narrow the propositions until each source says something true within scope.
4. If genuine split or tension remains, state it.
5. Record the conflict in both digest and audit.

Conflict types: official text vs commentary, old case vs current doctrine, circuit vs circuit, agency guidance vs judicial narrowing, historical term vs current term, broad explainer vs narrow holding.

---

## Terminology Discipline

Never swap words casually. Investigate: whether the old term remains in cases; whether it is now historical only; whether modern doctrine covers more or less than the old term; whether modern statutory language differs from old doctrinal shorthand; whether the old term creates ambiguity.

The digest must then explain: the historical label, the modern treatment, when the older term is still necessary for source accuracy, and when it must not be used as the present doctrinal category.

---

## Practical Significance and Related Concepts

**Practical significance** answers: why does this issue matter in litigation, compliance, administration, or rights assertion? What consequences follow from the current framework? What misunderstandings affect practitioners? What recent shifts make it newly salient? Law-firm materials may help here but never substitute for primary law in doctrinal sections. Not free-floating policy writing.

**Related Concepts** clarifies boundaries without broadening the research target: this issue vs a neighboring defense, this test vs a broader standard, this procedural doctrine vs a remedial doctrine, this constitutional principle vs a statutory implementation. Not a dumping ground for everything interesting nearby.

---

## Failure Logging

Failure is part of the research record. Always log: branch failures, failed searches, empty results, inaccessible sources, tool errors, conversion errors, query dead ends, jurisdiction uncertainty, unresolved authority gaps.

Good: `Search for exact issue phrase on govinfo returned no directly relevant results.` / `CourtListener opinion page identified, but mechanical conversion failed due to extraction error.` / `No contrary authority found after searching exact issue, narrower issue, and limiting-phrase variants.`

Bad: `Could not find much.` / `Tool weirdness.` / `Some pages failed.`

Precision matters.

---

## Snippet Discipline

A factual snippet is small, attributable, and proposition-specific: one sentence from a statute defining a term, one passage from a case stating a standard, one excerpt from an agency page stating guidance scope. Bad: multi-paragraph blobs with mixed propositions, extracts with no identified function, summary prose written from memory, snippets used because the full source was hard to read.

---

## Style Rules

**Digest:** direct, source-supported, low-drama, explicit about uncertainty, careful with scope, readable by a lawyer or legal technologist, organized by doctrinal function rather than essay flow. Avoid unsupported thesis statements, rhetorical certainty, broad legal history that doesn't serve the issue, pseudo-neutral phrasing that hides real conflict, conclusory prose.

**Audit:** a disciplined build log, allowed to be blunt — `Rejected: law-firm alert overstated holding; useful only for recent-awareness lead.` / `Gap: no accessible free source found for historical agency memo text.` The audit is a record, not marketing copy.

**Bundle-writing posture:** write the digest as if a skeptical maintainer will diff it against the audit; the audit as if diffed against the source files; the source files as if diffed against the public originals.

---

## Optional Reports

- `report.md`: only if the workflow expects a standalone report separate from the digest; otherwise report it was not separately emitted.
- `reports/sources/` (`synthesis_mode="split"`): one report per retained source, using only accepted findings and that source's role.
- `reports/sections/` (`synthesis_mode="sections"`): one report per outline section, named with ordered numeric prefixes and section slugs.

Optional reports supplement the bundle; they never replace digest or audit.

---

## Notation Examples

- `CONTRACT_LAW.FORMATION.CAPACITY.MINORS`
- `CONSTITUTIONAL_LAW.FIRST_AMENDMENT.FREE_PRESS.PRIOR_RESTRAINT`
- `ADMINISTRATIVE_LAW.AGENCY_ACTION.ARBITRARY_AND_CAPRICIOUS_REVIEW`

`id` must exactly match `urn:legal-taxonomy:issue:<notation>`.

---

## Anti-Patterns

1. **Topic drift** — starting with one issue and ending with a survey of the surrounding area.
2. **Case-name glitter** — dropping famous cases that aren't carefully tied to issue-specific propositions.
3. **Terminology laundering** — presenting an older term as present doctrine without checking currency.
4. **Source laundering** — citing a public article that summarizes a paywalled source as if the underlying authority were inspected.
5. **Certainty smoothing** — turning mixed or conflicting evidence into clean declarative prose without caveats.
6. **Audit cosplay** — a structured-looking audit that omits rejected sources, failed searches, or unused snippets.
7. **Batch merge** — summarizing 30 subquestions into "the important ones" and shipping 8. Forbidden.
8. **Zombie run** — ending neither MERGED nor CLOSED: files delivered with no declared terminal state, or a silent stop. Forbidden.
9. **State-file clobber** — rewriting, reformatting, reordering, or "fixing" a runner-owned `run.json` instead of appending one record to it. Forbidden.
10. **Bare verdict** — recording `MERGED` or `CLOSED` with no gate item, no counts, no defensible reason. A label is not a record.
11. **Reason drift** — a friendlier reason in the message than in the run record, or counts that differ between the two.
