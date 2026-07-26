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
- Leave runner-owned files (`caselaw_index.md`, `statutory_index.md`, `run.json`) to the runner. Skeletons created at materialization time are overwritten by the runner after your run.

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
