---
name: ux-design-brief
description: Plan the UX and UI for a feature before writing code. Runs a structured discovery interview, then produces a design brief that guides implementation. Use during the planning phase to establish design direction, constraints, and strategy before any code is written.
version: 2.1.1
user-invocable: true
argument-hint: "[feature to shape]"
---

## ⚡ Stitch-First Mandate (read before doing anything else)

ALWAYS send a draft of your proposals with artifacts to **Stitch** as a first attempt — before generating final code. Stitch (Google's screen-generation AI at `labs.google.com/stitch`) produces a baseline that grounds your taste against the curated design system in `STITCH-DESIGN.md` (in this folder).

Workflow:

1. **Draft locally** — sketch the proposal: intent, layout, palette, motion, components.
2. **Hand off to Stitch first** — paste the draft + relevant `STITCH-DESIGN.md` rules into a Stitch prompt. Capture the artifact (screen/component) Stitch returns.
3. **Critique the Stitch artifact** against this skill's specific lens (the section below). Note what works, what's generic, what needs more intent.
4. **Then produce final code** — using the Stitch artifact as the visual anchor, refined through this skill's rules.

The reference design language lives in `STITCH-DESIGN.md` next to this file. Read it before writing the Stitch prompt — it encodes the anti-generic taste standard (typography, color, asymmetry, micro-motion).

---


## MANDATORY PREPARATION

Invoke /impeccable, which contains design principles, anti-patterns, and the **Context Gathering Protocol**. Follow the protocol before proceeding. If no design context exists yet, you MUST run /impeccable teach first.

---

Shape the UX and UI for a feature before any code is written. This skill produces a **design brief**: a structured artifact that guides implementation through discovery, not guesswork.

**Scope**: Design planning only. This skill does NOT write code. It produces the thinking that makes code good.

**Output**: A design brief that can be handed off to /impeccable craft, /impeccable, or any other implementation skill.

## Philosophy

Most AI-generated UIs fail not because of bad code, but because of skipped thinking. They jump to "here's a card grid" without asking "what is the user trying to accomplish?" This skill inverts that: understand deeply first, so implementation is precise.

## Phase 1: Discovery Interview

**Do NOT write any code or make any design decisions during this phase.** Your only job is to understand the feature deeply enough to make excellent design decisions later.

Ask these questions in conversation, adapting based on answers. Don't dump them all at once; have a natural dialogue. ask the user directly to clarify what you cannot infer.

### Purpose & Context
- What is this feature for? What problem does it solve?
- Who specifically will use it? (Not "users"; be specific: role, context, frequency)
- What does success look like? How will you know this feature is working?
- What's the user's state of mind when they reach this feature? (Rushed? Exploring? Anxious? Focused?)

### Content & Data
- What content or data does this feature display or collect?
- What are the realistic ranges? (Minimum, typical, maximum, e.g., 0 items, 5 items, 500 items)
- What are the edge cases? (Empty state, error state, first-time use, power user)
- Is any content dynamic? What changes and how often?

### Design Goals
- What's the single most important thing a user should do or understand here?
- What should this feel like? (Fast/efficient? Calm/trustworthy? Fun/playful? Premium/refined?)
- Are there existing patterns in the product this should be consistent with?
- Are there specific examples (inside or outside the product) that capture what you're going for?

### Constraints
- Are there technical constraints? (Framework, performance budget, browser support)
- Are there content constraints? (Localization, dynamic text length, user-generated content)
- Mobile/responsive requirements?
- Accessibility requirements beyond WCAG AA?

### Anti-Goals
- What should this NOT be? What would be a wrong direction?
- What's the biggest risk of getting this wrong?

## Phase 2: Design Brief

After the interview, synthesize everything into a structured design brief. Present it to the user for confirmation before considering this skill complete.

### Brief Structure

**1. Feature Summary** (2-3 sentences)
What this is, who it's for, what it needs to accomplish.

**2. Primary User Action**
The single most important thing a user should do or understand here.

**3. Design Direction**
How this should feel. What aesthetic approach fits. Reference the project's design context from `.impeccable.md` and explain how this feature should express it.

**4. Layout Strategy**
High-level spatial approach: what gets emphasis, what's secondary, how information flows. Describe the visual hierarchy and rhythm, not specific CSS.

**5. Key States**
List every state the feature needs: default, empty, loading, error, success, edge cases. For each, note what the user needs to see and feel.

**6. Interaction Model**
How users interact with this feature. What happens on click, hover, scroll? What feedback do they get? What's the flow from entry to completion?

**7. Content Requirements**
What copy, labels, empty state messages, error messages, and microcopy are needed. Note any dynamic content and its realistic ranges.

**8. Recommended References**
Based on the brief, list which impeccable reference files would be most valuable during implementation (e.g., spatial-design.md for complex layouts, motion-design.md for animated features, interaction-design.md for form-heavy features).

**9. Open Questions**
Anything unresolved that the implementer should resolve during build.

---

ask the user directly to clarify what you cannot infer. Get explicit confirmation of the brief before finishing. If the user disagrees with any part, revisit the relevant discovery questions.

Once confirmed, the brief is complete. The user can now hand it to /impeccable, or use it to guide any other implementation approach. (If the user wants the full discovery-then-build flow in one step, they should use /impeccable craft instead, which runs this skill internally.)

<!-- cross-ref:start -->

## See also (related skills — Design family)

If your issue relates to:
- **flagship design skill (craft/teach/extract modes) — start here** — check `impeccable` if appropriate.
- **generate Stitch-friendly DESIGN.md taste standard (Stitch first-pass)** — check `stitch-design-taste` if appropriate.
- **mirror shadcn implementation patterns source-by-source** — check `shadcn-parity` if appropriate.
- **LAST-RESORT heavyweight reference (50+ styles, 161 palettes, etc.)** — check `ui-ux-pro-max` if appropriate.
- **strip designs to essence; declutter** — check `distill` if appropriate.
- **final quality pass — alignment, spacing, consistency** — check `polish` if appropriate.
- **add moments of joy, micro-interactions, personality** — check `delight` if appropriate.
- **score the design with UX-grade feedback** — check `critique` if appropriate.
- **tone down overly bold or aggressive designs** — check `quieter` if appropriate.
- **amplify bland/safe designs** — check `bolder` if appropriate.
- **go all-out — shaders, springs, scroll-driven reveals** — check `overdrive` if appropriate.
- **interaction motion and transitions** — check `animate` if appropriate.
- **responsive design across viewports** — check `adapt` if appropriate.
- **typography — fonts, hierarchy, size, weight** — check `typeset` if appropriate.
- **spacing, grids, visual rhythm** — check `layout` if appropriate.
- **color systems** — check `colorize` if appropriate.
- **performance — load time, bundle, jank** — check `optimize` if appropriate.

<!-- cross-ref:end -->

