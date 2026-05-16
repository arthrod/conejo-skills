---
name: adr
description: Architectural Decision Record (ADR) workflow — extract decisions from conversations/transcripts, then format them as MADR documents with Definition of Done (E.C.A.D.R.). Covers the full extract → write pipeline. Triggers on "what decisions did we make", "write the ADR", "format as MADR", "check ADR quality", "summarize architectural decisions".
---

# ADR — Extract & Write

This skill handles both halves of the ADR pipeline:

| Phase | Section |
|---|---|
| **Mine** a conversation/transcript for architectural decisions | [Extraction](#decision-extraction) |
| **Format** an extracted decision as a MADR document | [Writing](#adr-writing-madr) |

If you only have raw discussion → start at extraction. If you already have a clear decision → jump to writing.

---

# Decision Extraction


# ADR Decision Extraction

Extract architectural decisions from conversation context for ADR generation.

## Detection Signals

| Signal Type | Examples |
|-------------|----------|
| Explicit markers | `[ADR]`, "decided:", "the decision is" |
| Choice patterns | "let's go with X", "we'll use Y", "choosing Z" |
| Trade-off discussions | "X vs Y", "pros/cons", "considering alternatives" |
| Problem-solution pairs | "the problem is... so we'll..." |

## Extraction Rules

### Explicit Tags (Guaranteed Inclusion)

Text marked with `[ADR]` is always extracted:

```
[ADR] Using PostgreSQL for user data storage due to ACID requirements
```

These receive `confidence: "high"` automatically.

### AI-Detected Decisions

Patterns detected without explicit tags require confidence assessment:

| Confidence | Criteria |
|------------|----------|
| **high** | Clear statement of choice with rationale |
| **medium** | Implied decision from action taken |
| **low** | Contextual inference, may need verification |

## Output Format

```json
{
  "decisions": [
    {
      "title": "Use PostgreSQL for user data",
      "problem": "Need ACID transactions for financial records",
      "chosen_option": "PostgreSQL",
      "alternatives_discussed": ["MongoDB", "SQLite"],
      "drivers": ["ACID compliance", "team familiarity"],
      "confidence": "high",
      "source_context": "Discussion about database selection in planning phase"
    }
  ]
}
```

### Field Definitions

| Field | Required | Description |
|-------|----------|-------------|
| `title` | Yes | Concise decision summary |
| `problem` | Yes | Problem or context driving the decision |
| `chosen_option` | Yes | The selected solution or approach |
| `alternatives_discussed` | No | Other options mentioned (empty array if none) |
| `drivers` | No | Factors influencing the decision |
| `confidence` | Yes | `high`, `medium`, or `low` |
| `source_context` | No | Brief description of where decision appeared |

## Extraction Workflow

1. **Scan for explicit markers** - Find all `[ADR]` tagged content
2. **Identify choice patterns** - Look for decision language
3. **Extract trade-off discussions** - Capture alternatives and reasoning
4. **Assess confidence** - Rate each non-explicit decision
5. **Capture context** - Note surrounding discussion for ADR writer

## Pattern Examples

### High Confidence

```
"We decided to use Redis for caching because of its sub-millisecond latency
and native TTL support. Memcached was considered but lacks persistence."
```

Extracts:
- Title: Use Redis for caching
- Problem: Need fast caching with TTL
- Chosen: Redis
- Alternatives: Memcached
- Drivers: sub-millisecond latency, native TTL, persistence
- Confidence: high

### Medium Confidence

```
"Let's go with TypeScript for the frontend since we're already using it
in the backend."
```

Extracts:
- Title: Use TypeScript for frontend
- Problem: Language choice for frontend
- Chosen: TypeScript
- Alternatives: (none stated)
- Drivers: consistency with backend
- Confidence: medium

### Low Confidence

```
"The API seems to be working well with REST endpoints."
```

Extracts:
- Title: REST API architecture
- Problem: API design approach
- Chosen: REST
- Alternatives: (none stated)
- Drivers: (none stated)
- Confidence: low

## Best Practices

### Context Capture

Always capture sufficient context for the ADR writer:
- What was the discussion about?
- Who was involved (if known)?
- What prompted the decision?

### Merge Related Decisions

If multiple statements relate to the same decision, consolidate them:
- Combine alternatives from different mentions
- Aggregate drivers
- Use highest confidence level

### Flag Ambiguity

When decisions are unclear or contradictory:
- Note the ambiguity in `source_context`
- Set confidence to `low`
- Include all interpretations if multiple exist

## When to Use This Skill

- Analyzing session transcripts for ADR generation
- Reviewing conversation history for documentation
- Extracting decisions from design discussions
- Preparing input for ADR writing tools

---

# ADR Writing (MADR)


# ADR Writing

## Overview

Generate Architectural Decision Records (ADRs) following the MADR template with systematic completeness checking.

## Quick Reference

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  SEQUENCE   │ ──▶ │   EXPLORE    │ ──▶ │    FILL     │
│  (get next  │     │  (context,   │     │  (template  │
│   number)   │     │   ADRs)      │     │   sections) │
└─────────────┘     └──────────────┘     └─────────────┘
       │                                        │
       │                                        ▼
       │                                 ┌─────────────┐
       │                                 │   VERIFY    │
       │                                 │  (DoD       │
       └─────────────────────────────────│   checklist)│
                                         └─────────────┘
```

## When To Use

- Documenting architectural decisions from extracted requirements
- Converting meeting notes or discussions to formal ADRs
- Recording technical choices from PR discussions
- Creating decision records from design documents

## Workflow

### Step 1: Get Sequence Number

**If a number was pre-assigned** (e.g., when called from `/beagle:write-adr` with parallel writes):
- Use the pre-assigned number directly
- Do NOT call the script - this prevents duplicate numbers in parallel execution

**If no number was pre-assigned** (standalone use):
```bash
python scripts/next_adr_number.py
```

This outputs the next available ADR number (e.g., `0003`).

For parallel allocation (used by parent commands):
```bash
python scripts/next_adr_number.py --count 3
# Outputs: 0003, 0004, 0005 (one per line)
```

### Step 2: Explore Context

Before writing, gather additional context:

1. **Related code** - Find implementations affected by this decision
2. **Existing ADRs** - Check `docs/adrs/` for related or superseded decisions
3. **Discussion sources** - PRs, issues, or documents referenced in decision

### Step 3: Load Template

Load `references/madr-template.md` for the official MADR structure.

### Step 4: Fill Sections

Populate each section from your decision data:

| Section | Source |
|---------|--------|
| Title | Decision summary (imperative mood) |
| Status | Always `draft` initially |
| Context | Problem statement, constraints |
| Decision Drivers | Prioritized requirements |
| Considered Options | All viable alternatives |
| Decision Outcome | Chosen option with rationale |
| Consequences | Good, bad, neutral impacts |

### Step 5: Apply Definition of Done

Load `references/definition-of-done.md` and verify E.C.A.D.R. criteria:

- **E**xplicit problem statement
- **C**omprehensive options analysis
- **A**ctionable decision
- **D**ocumented consequences
- **R**eviewable by stakeholders

### Step 6: Mark Gaps

For sections that cannot be filled from available data, insert investigation prompts:

```markdown
* [INVESTIGATE: Review PR #42 discussion for additional drivers]
* [INVESTIGATE: Confirm with security team on compliance requirements]
* [INVESTIGATE: Benchmark performance of Option 2 vs Option 3]
```

These prompts signal incomplete sections for later follow-up.

### Step 7: Write File

**IMPORTANT: Every ADR MUST start with YAML frontmatter.**

The frontmatter block is REQUIRED and must include at minimum:
```yaml
status: draft
date: YYYY-MM-DD
```

Full frontmatter template:
```yaml
status: draft
date: 2024-01-15
decision-makers: [alice, bob]
consulted: []
informed: []
```

**Validation:** Before writing the file, verify the content starts with `---` followed by valid YAML frontmatter. If frontmatter is missing, add it before writing.

Save to `docs/adrs/NNNN-slugified-title.md`:

```
docs/adrs/0003-use-postgresql-for-user-data.md
docs/adrs/0004-adopt-event-sourcing-pattern.md
docs/adrs/0005-migrate-to-kubernetes.md
```

### Step 8: Verify Frontmatter

After writing, confirm the file:
1. Starts with `---` on the first line
2. Contains `status: draft` (or other valid status)
3. Contains `date: YYYY-MM-DD` with actual date
4. Ends frontmatter with `---` before the title

## File Naming Convention

Format: `NNNN-slugified-title.md`

| Component | Rule |
|-----------|------|
| `NNNN` | Zero-padded sequence number from script |
| `-` | Separator |
| `slugified-title` | Lowercase, hyphens, no special characters |
| `.md` | Markdown extension |

## Reference Files

- `references/madr-template.md` - Official MADR template structure
- `references/definition-of-done.md` - E.C.A.D.R. quality criteria

## Output Example

```markdown
status: draft
date: 2024-01-15
decision-makers: [alice, bob]

# Use PostgreSQL for User Data Storage

## Context and Problem Statement

We need a database for user account data...

## Decision Drivers

* Data integrity requirements
* Query flexibility needs
* [INVESTIGATE: Confirm scaling projections with infrastructure team]

## Considered Options

* PostgreSQL
* MongoDB
* CockroachDB

## Decision Outcome

Chosen option: PostgreSQL, because...

## Consequences

### Good

* ACID compliance ensures data integrity

### Bad

* Requires more upfront schema design

### Neutral

* Team has moderate PostgreSQL experience
```
