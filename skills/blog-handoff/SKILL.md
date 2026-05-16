---
name: blog-handoff
description: Use when a research/development session is ending and the work needs to be captured for a blog post writer. Triggers on "handoff", "blog post", "write up the work", "capture for blog", "document what we did". You MUST pass log locations for investigation.
---

# Blog Handoff

## Overview

Generates a structured handoff document — primarily a **link organizer with a search manual** — so a blog post writer agent can find the important parts of a long session without reading the entire transcript.

**The goal is to document THE PROCESS** — how a problem evolved through iterations (v1, v2, v3...), what drove each change, and how conclusions were reached.

## BEFORE GENERATING: Interactive Confirmation

**You MUST use AskUserQuestion to confirm your choices iteratively.** Do NOT dump the handoff. Walk through decisions in batches of up to 4 questions.

### Round 1: Scope & Files
Use AskUserQuestion to confirm which files to include and why. For each file/group, explain what you're sending and why, or why you're skipping it. Example questions:

- "I found these output files: [list]. Which matter for the blog?" (multiSelect)
- "The transcript is [size]. I'll point to key sections instead of including everything — agree?"
- "Should I include the intermediate versions (v2, v3) or just v1 and final?"

### Round 2: Key Moments
Use AskUserQuestion to confirm which conversation moments to highlight:

- "I think the biggest pivot was when [X]. Is that right, or was it something else?"
- "You seemed frustrated around [keyword/topic]. Should I flag that for the writer?"
- "The model got [X] wrong and you corrected it around [topic]. Include this?"

### Round 3: Framing
- "One post or multiple? I see [N] natural breaks."
- "Who's the audience — ML engineers, general devs, your team?"

Keep going until the user is satisfied. Each round uses AskUserQuestion with concrete choices, not open-ended prose.

## MANDATORY: Log Locations

You MUST include:
1. **Conversation transcript(s)**: `~/.claude/projects/<project-dir>/<session-id>.jsonl`
2. **Context compactions**: Point out that compaction summaries in the transcript reveal model reasoning and frustrations.
3. **Working directory**: absolute path
4. **All output files**: every data file produced, with why each matters

## Handoff Document Structure

Write to `BLOG_HANDOFF.md` in the working directory. This is a **search manual**, not a retelling.

```markdown
# Blog Handoff: [Title]

## TL;DR
[1-2 sentences: what was done, what was found]

## Session Logs
- **Transcript(s)**: [absolute paths to .jsonl files]
- **Working directory**: [absolute path]
- **Previous session** (if any): [path]
- **Compaction summaries**: Review these in the transcript — they show model priorities and can reveal model frustrations.

## Where to Find What (Search Manual)
[This is the MOST IMPORTANT section. The blog writer has a huge transcript. Tell them exactly where to look.]

### The Process Evolution
| Version | What changed | Why | Search transcript for |
|---------|-------------|-----|----------------------|
| V1 | [approach] | [initial attempt] | "search keyword" |
| V2 | [what changed] | [what broke in V1] | "search keyword" |
| V3 | [what changed] | [insight from V2] | "search keyword" |
| ... | | | |

### Key Moments to Find
| Moment | What happened | Search for |
|--------|--------------|------------|
| User surprise | [what surprised them] | "exact phrase or keyword" |
| User frustration | [what went wrong] | "exact phrase or keyword" |
| Model mistake | [what model got wrong] | "exact phrase or keyword" |
| Pivot point | [when approach changed] | "exact phrase or keyword" |
| Communication friction | [hard to convey idea] | "exact phrase or keyword" |

### Model Introspection Points
| What | Where to look |
|------|--------------|
| Model wrong assumption | Search for "keyword" |
| Model corrected by user | Search for "keyword" |
| Compaction reveals priority | Check compaction around message N |

## Results Summary
[Exact numbers. Comparison tables across versions. Copied from actual output files, never rounded.]

## Files Index
| File | Why it matters | Key content |
|------|---------------|-------------|
| path/to/file | [why the writer needs this] | [what's in it] |

## Raw Data Pointers
[Absolute paths to every output file the writer needs to verify numbers]

## Open Questions
[Unresolved items]
```

## What Makes a Good Handoff

- **Search keywords, not summaries**: Point the writer to WHERE, don't retell
- **Explain WHY each file is included**: "this shows the v3→v4 jump" not just "output file"
- **Flag the human moments**: user surprise, frustration, enthusiasm — with search terms
- **Flag model friction**: where model was confused, made wrong assumptions, got corrected
- **Version evolution table**: the v1→vN journey with cause-and-effect is mandatory
- **Exact numbers**: copy from outputs, never round

## Decision Reasoning (CRITICAL)

Every major decision in the handoff MUST include **why** it was made, not just what was done. The blog writer needs to understand the reasoning chain so they can explain it to readers.

For each version in the Process Evolution table, the "Why" column must answer:
- What problem or failure motivated this change?
- What alternatives were considered and rejected?
- What was the reasoning that led to this specific choice?

For example:
- BAD: "Switched to mxbai-embed-large-v1"
- GOOD: "Switched to mxbai-embed-large-v1 because bge-small's 384d space was too dense — all labels clustered between 0.40-0.65, making it impossible to distinguish synonyms from unrelated concepts. The 1024d model gave a wider range (0.33-0.95) where the synonym boundary was actually meaningful."

Add a dedicated section to the handoff:

### Decision Log
| Decision | Alternatives considered | Why this choice | Search for |
|----------|------------------------|-----------------|------------|
| [what was decided] | [what else could have been done] | [the reasoning] | "keyword" |

This is especially important for:
- Tool/library choices (why THIS embedding model? why THIS threshold?)
- Methodology choices (why distractors instead of something else? why distractor-only instead of mixed?)
- Architecture choices (why LLM judge? why not manual inspection?)
- Pivots (why did we abandon approach X for approach Y?)

## Common Mistakes

- Retelling the conversation instead of pointing to it
- Not providing searchable keywords (forces full transcript read)
- Dumping files without explaining why each matters
- Missing conversation transcript paths
- Skipping compaction summaries
- Not using AskUserQuestion to confirm choices
- **Missing the "why" behind decisions** — listing what changed without explaining the reasoning that led to it. The blog writer can see WHAT happened from the code; they need the handoff to explain WHY.

<!-- cross-ref:start -->

## See also (related skills — Blog family)

If your issue relates to:
- **write the blog post from a handoff doc** — check `blog-writing` if appropriate.

<!-- cross-ref:end -->

