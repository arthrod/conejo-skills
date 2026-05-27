---
name: refine-distill-frontend
description: Refine a frontend design — strip complexity, polish details, and tone down intensity. Three modes — Distill (strip to essence, declutter, reduce noise), Polish (final quality pass: alignment, spacing, consistency, micro-detail), and Quieter (tone down overly bold/aggressive/garish designs). Use when the user wants the UI to feel calmer, cleaner, or more refined — "simplify", "too much going on", "polish before ship", "too loud", "too aggressive", "make it cleaner".
---

# Refine / Distill / Frontend

Three modes for reducing intensity and tightening a design.

| Mode | When |
|---|---|
| **Distill** | Strip designs to their essence — remove the unnecessary so the remaining feels powerful |
| **Polish** | Final pre-ship quality pass — alignment, spacing, consistency, micro-details |
| **Quieter** | Tone down designs that are too bold/aggressive/garish — calmer, more refined |

If unsure which: **Polish** is the safest (pre-ship), **Distill** is the structural (reduce elements), **Quieter** is the perceptual (reduce intensity of remaining elements).


---

# Distill mode (strip to essence)


## ⚡ Stitch-First Mandate (read before doing anything else)

ALWAYS send a draft of your proposals with artifacts to **Stitch** as a first attempt — before generating final code. Stitch (Google's screen-generation AI at `labs.google.com/stitch`) produces a baseline that grounds your taste against the curated design system in `STITCH-DESIGN.md` (in this folder).

Workflow:

1. **Draft locally** — sketch the proposal: intent, layout, palette, motion, components.
2. **Hand off to Stitch first** — paste the draft + relevant `STITCH-DESIGN.md` rules into a Stitch prompt. Capture the artifact (screen/component) Stitch returns.
3. **Critique the Stitch artifact** against this skill's specific lens (the section below). Note what works, what's generic, what needs more intent.
4. **Then produce final code** — using the Stitch artifact as the visual anchor, refined through this skill's rules.

The reference design language lives in `STITCH-DESIGN.md` next to this file. Read it before writing the Stitch prompt — it encodes the anti-generic taste standard (typography, color, asymmetry, micro-motion).



Remove unnecessary complexity from designs, revealing the essential elements and creating clarity through ruthless simplification.

## MANDATORY PREPARATION

Invoke /impeccable — it contains design principles, anti-patterns, and the **Context Gathering Protocol**. Follow the protocol before proceeding — if no design context exists yet, you MUST run /impeccable teach first.


## Assess Current State

Analyze what makes the design feel complex or cluttered:

1. **Identify complexity sources**:
   - **Too many elements**: Competing buttons, redundant information, visual clutter
   - **Excessive variation**: Too many colors, fonts, sizes, styles without purpose
   - **Information overload**: Everything visible at once, no progressive disclosure
   - **Visual noise**: Unnecessary borders, shadows, backgrounds, decorations
   - **Confusing hierarchy**: Unclear what matters most
   - **Feature creep**: Too many options, actions, or paths forward

2. **Find the essence**:
   - What's the primary user goal? (There should be ONE)
   - What's actually necessary vs nice-to-have?
   - What can be removed, hidden, or combined?
   - What's the 20% that delivers 80% of value?

If any of these are unclear from the codebase, ask the user directly to clarify what you cannot infer.

**CRITICAL**: Simplicity is not about removing features - it's about removing obstacles between users and their goals. Every element should justify its existence.

## Plan Simplification

Create a ruthless editing strategy:

- **Core purpose**: What's the ONE thing this should accomplish?
- **Essential elements**: What's truly necessary to achieve that purpose?
- **Progressive disclosure**: What can be hidden until needed?
- **Consolidation opportunities**: What can be combined or integrated?

**IMPORTANT**: Simplification is hard. It requires saying no to good ideas to make room for great execution. Be ruthless.

## Simplify the Design

Systematically remove complexity across these dimensions:

### Information Architecture
- **Reduce scope**: Remove secondary actions, optional features, redundant information
- **Progressive disclosure**: Hide complexity behind clear entry points (accordions, modals, step-through flows)
- **Combine related actions**: Merge similar buttons, consolidate forms, group related content
- **Clear hierarchy**: ONE primary action, few secondary actions, everything else tertiary or hidden
- **Remove redundancy**: If it's said elsewhere, don't repeat it here

### Visual Simplification
- **Reduce color palette**: Use 1-2 colors plus neutrals, not 5-7 colors
- **Limit typography**: One font family, 3-4 sizes maximum, 2-3 weights
- **Remove decorations**: Eliminate borders, shadows, backgrounds that don't serve hierarchy or function
- **Flatten structure**: Reduce nesting, remove unnecessary containers—never nest cards inside cards
- **Remove unnecessary cards**: Cards aren't needed for basic layout; use spacing and alignment instead
- **Consistent spacing**: Use one spacing scale, remove arbitrary gaps

### Layout Simplification
- **Linear flow**: Replace complex grids with simple vertical flow where possible
- **Remove sidebars**: Move secondary content inline or hide it
- **Full-width**: Use available space generously instead of complex multi-column layouts
- **Consistent alignment**: Pick left or center, stick with it
- **Generous white space**: Let content breathe, don't pack everything tight

### Interaction Simplification
- **Reduce choices**: Fewer buttons, fewer options, clearer path forward (paradox of choice is real)
- **Smart defaults**: Make common choices automatic, only ask when necessary
- **Inline actions**: Replace modal flows with inline editing where possible
- **Remove steps**: Can signup be one step instead of three? Can checkout be simplified?
- **Clear CTAs**: ONE obvious next step, not five competing actions

### Content Simplification
- **Shorter copy**: Cut every sentence in half, then do it again
- **Active voice**: "Save changes" not "Changes will be saved"
- **Remove jargon**: Plain language always wins
- **Scannable structure**: Short paragraphs, bullet points, clear headings
- **Essential information only**: Remove marketing fluff, legalese, hedging
- **Remove redundant copy**: No headers restating intros, no repeated explanations, say it once

### Code Simplification
- **Remove unused code**: Dead CSS, unused components, orphaned files
- **Flatten component trees**: Reduce nesting depth
- **Consolidate styles**: Merge similar styles, use utilities consistently
- **Reduce variants**: Does that component need 12 variations, or can 3 cover 90% of cases?

**NEVER**:
- Remove necessary functionality (simplicity ≠ feature-less)
- Sacrifice accessibility for simplicity (clear labels and ARIA still required)
- Make things so simple they're unclear (mystery ≠ minimalism)
- Remove information users need to make decisions
- Eliminate hierarchy completely (some things should stand out)
- Oversimplify complex domains (match complexity to actual task complexity)

## Verify Simplification

Ensure simplification improves usability:

- **Faster task completion**: Can users accomplish goals more quickly?
- **Reduced cognitive load**: Is it easier to understand what to do?
- **Still complete**: Are all necessary features still accessible?
- **Clearer hierarchy**: Is it obvious what matters most?
- **Better performance**: Does simpler design load faster?

## Document Removed Complexity

If you removed features or options:
- Document why they were removed
- Consider if they need alternative access points
- Note any user feedback to monitor

Remember: You have great taste and judgment. Simplification is an act of confidence - knowing what to keep and courage to remove the rest. As Antoine de Saint-Exupéry said: "Perfection is achieved not when there is nothing more to add, but when there is nothing left to take away."

<!-- cross-ref:start -->

## See also (related skills — Design family)

If your issue relates to:
- **flagship design skill (craft/teach/extract modes) — start here** — check `impeccable` if appropriate.
- **generate Stitch-friendly DESIGN.md taste standard (Stitch first-pass)** — check `stitch-design-taste` if appropriate.
- **plan UX/UI for a feature before writing code (design brief)** — check `ux-design-brief` if appropriate.
- **mirror shadcn implementation patterns source-by-source** — check `shadcn-parity` if appropriate.
- **LAST-RESORT heavyweight reference (50+ styles, 161 palettes, etc.)** — check `ui-ux-pro-max` if appropriate.
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


---

# Polish mode (final pre-ship pass)


## ⚡ Stitch-First Mandate (read before doing anything else)

ALWAYS send a draft of your proposals with artifacts to **Stitch** as a first attempt — before generating final code. Stitch (Google's screen-generation AI at `labs.google.com/stitch`) produces a baseline that grounds your taste against the curated design system in `STITCH-DESIGN.md` (in this folder).

Workflow:

1. **Draft locally** — sketch the proposal: intent, layout, palette, motion, components.
2. **Hand off to Stitch first** — paste the draft + relevant `STITCH-DESIGN.md` rules into a Stitch prompt. Capture the artifact (screen/component) Stitch returns.
3. **Critique the Stitch artifact** against this skill's specific lens (the section below). Note what works, what's generic, what needs more intent.
4. **Then produce final code** — using the Stitch artifact as the visual anchor, refined through this skill's rules.

The reference design language lives in `STITCH-DESIGN.md` next to this file. Read it before writing the Stitch prompt — it encodes the anti-generic taste standard (typography, color, asymmetry, micro-motion).



## MANDATORY PREPARATION

Invoke /impeccable — it contains design principles, anti-patterns, and the **Context Gathering Protocol**. Follow the protocol before proceeding — if no design context exists yet, you MUST run /impeccable teach first. Additionally gather: quality bar (MVP vs flagship).


Perform a meticulous final pass to catch all the small details that separate good work from great work. The difference between shipped and polished.

## Design System Discovery

Before polishing, understand the system you are polishing toward:

1. **Find the design system**: Search for design system documentation, component libraries, style guides, or token definitions. Study the core patterns: color tokens, spacing scale, typography styles, component API.
2. **Note the conventions**: How are shared components imported? What spacing scale is used? Which colors come from tokens vs hard-coded values? What motion and interaction patterns are established?
3. **Identify drift**: Where does the target feature deviate from the system? Hard-coded values that should be tokens, custom components that duplicate shared ones, spacing that doesn't match the scale.

If a design system exists, polish should align the feature with it. If none exists, polish against the conventions visible in the codebase.

## Pre-Polish Assessment

Understand the current state and goals:

1. **Review completeness**:
   - Is it functionally complete?
   - Are there known issues to preserve (mark with TODOs)?
   - What's the quality bar? (MVP vs flagship feature?)
   - When does it ship? (How much time for polish?)

2. **Identify polish areas**:
   - Visual inconsistencies
   - Spacing and alignment issues
   - Interaction state gaps
   - Copy inconsistencies
   - Edge cases and error states
   - Loading and transition smoothness

**CRITICAL**: Polish is the last step, not the first. Don't polish work that's not functionally complete.

## Polish Systematically

Work through these dimensions methodically:

### Visual Alignment & Spacing

- **Pixel-perfect alignment**: Everything lines up to grid
- **Consistent spacing**: All gaps use spacing scale (no random 13px gaps)
- **Optical alignment**: Adjust for visual weight (icons may need offset for optical centering)
- **Responsive consistency**: Spacing and alignment work at all breakpoints
- **Grid adherence**: Elements snap to baseline grid

**Check**:
- Enable grid overlay and verify alignment
- Check spacing with browser inspector
- Test at multiple viewport sizes
- Look for elements that "feel" off

### Typography Refinement

- **Hierarchy consistency**: Same elements use same sizes/weights throughout
- **Line length**: 45-75 characters for body text
- **Line height**: Appropriate for font size and context
- **Widows & orphans**: No single words on last line
- **Hyphenation**: Appropriate for language and column width
- **Kerning**: Adjust letter spacing where needed (especially headlines)
- **Font loading**: No FOUT/FOIT flashes

### Color & Contrast

- **Contrast ratios**: All text meets WCAG standards
- **Consistent token usage**: No hard-coded colors, all use design tokens
- **Theme consistency**: Works in all theme variants
- **Color meaning**: Same colors mean same things throughout
- **Accessible focus**: Focus indicators visible with sufficient contrast
- **Tinted neutrals**: No pure gray or pure black—add subtle color tint (0.01 chroma)
- **Gray on color**: Never put gray text on colored backgrounds—use a shade of that color or transparency

### Interaction States

Every interactive element needs all states:

- **Default**: Resting state
- **Hover**: Subtle feedback (color, scale, shadow)
- **Focus**: Keyboard focus indicator (never remove without replacement)
- **Active**: Click/tap feedback
- **Disabled**: Clearly non-interactive
- **Loading**: Async action feedback
- **Error**: Validation or error state
- **Success**: Successful completion

**Missing states create confusion and broken experiences**.

### Micro-interactions & Transitions

- **Smooth transitions**: All state changes animated appropriately (150-300ms)
- **Consistent easing**: Use ease-out-quart/quint/expo for natural deceleration. Never bounce or elastic—they feel dated.
- **No jank**: 60fps animations, only animate transform and opacity
- **Appropriate motion**: Motion serves purpose, not decoration
- **Reduced motion**: Respects `prefers-reduced-motion`

### Content & Copy

- **Consistent terminology**: Same things called same names throughout
- **Consistent capitalization**: Title Case vs Sentence case applied consistently
- **Grammar & spelling**: No typos
- **Appropriate length**: Not too wordy, not too terse
- **Punctuation consistency**: Periods on sentences, not on labels (unless all labels have them)

### Icons & Images

- **Consistent style**: All icons from same family or matching style
- **Appropriate sizing**: Icons sized consistently for context
- **Proper alignment**: Icons align with adjacent text optically
- **Alt text**: All images have descriptive alt text
- **Loading states**: Images don't cause layout shift, proper aspect ratios
- **Retina support**: 2x assets for high-DPI screens

### Forms & Inputs

- **Label consistency**: All inputs properly labeled
- **Required indicators**: Clear and consistent
- **Error messages**: Helpful and consistent
- **Tab order**: Logical keyboard navigation
- **Auto-focus**: Appropriate (don't overuse)
- **Validation timing**: Consistent (on blur vs on submit)

### Edge Cases & Error States

- **Loading states**: All async actions have loading feedback
- **Empty states**: Helpful empty states, not just blank space
- **Error states**: Clear error messages with recovery paths
- **Success states**: Confirmation of successful actions
- **Long content**: Handles very long names, descriptions, etc.
- **No content**: Handles missing data gracefully
- **Offline**: Appropriate offline handling (if applicable)

### Responsiveness

- **All breakpoints**: Test mobile, tablet, desktop
- **Touch targets**: 44x44px minimum on touch devices
- **Readable text**: No text smaller than 14px on mobile
- **No horizontal scroll**: Content fits viewport
- **Appropriate reflow**: Content adapts logically

### Performance

- **Fast initial load**: Optimize critical path
- **No layout shift**: Elements don't jump after load (CLS)
- **Smooth interactions**: No lag or jank
- **Optimized images**: Appropriate formats and sizes
- **Lazy loading**: Off-screen content loads lazily

### Code Quality

- **Remove console logs**: No debug logging in production
- **Remove commented code**: Clean up dead code
- **Remove unused imports**: Clean up unused dependencies
- **Consistent naming**: Variables and functions follow conventions
- **Type safety**: No TypeScript `any` or ignored errors
- **Accessibility**: Proper ARIA labels and semantic HTML

## Polish Checklist

Go through systematically:

- [ ] Visual alignment perfect at all breakpoints
- [ ] Spacing uses design tokens consistently
- [ ] Typography hierarchy consistent
- [ ] All interactive states implemented
- [ ] All transitions smooth (60fps)
- [ ] Copy is consistent and polished
- [ ] Icons are consistent and properly sized
- [ ] All forms properly labeled and validated
- [ ] Error states are helpful
- [ ] Loading states are clear
- [ ] Empty states are welcoming
- [ ] Touch targets are 44x44px minimum
- [ ] Contrast ratios meet WCAG AA
- [ ] Keyboard navigation works
- [ ] Focus indicators visible
- [ ] No console errors or warnings
- [ ] No layout shift on load
- [ ] Works in all supported browsers
- [ ] Respects reduced motion preference
- [ ] Code is clean (no TODOs, console.logs, commented code)

**IMPORTANT**: Polish is about details. Zoom in. Squint at it. Use it yourself. The little things add up.

**NEVER**:
- Polish before it's functionally complete
- Spend hours on polish if it ships in 30 minutes (triage)
- Introduce bugs while polishing (test thoroughly)
- Ignore systematic issues (if spacing is off everywhere, fix the system)
- Perfect one thing while leaving others rough (consistent quality level)
- Create new one-off components when design system equivalents exist
- Hard-code values that should use design tokens

## Final Verification

Before marking as done:

- **Use it yourself**: Actually interact with the feature
- **Test on real devices**: Not just browser DevTools
- **Ask someone else to review**: Fresh eyes catch things
- **Compare to design**: Match intended design
- **Check all states**: Don't just test happy path

## Clean Up

After polishing, ensure code quality:

- **Replace custom implementations**: If the design system provides a component you reimplemented, switch to the shared version.
- **Remove orphaned code**: Delete unused styles, components, or files made obsolete by polish.
- **Consolidate tokens**: If you introduced new values, check whether they should be tokens.
- **Verify DRYness**: Look for duplication introduced during polishing and consolidate.

Remember: You have impeccable attention to detail and exquisite taste. Polish until it feels effortless, looks intentional, and works flawlessly. Sweat the details - they matter.

<!-- cross-ref:start -->

## See also (related skills — Design family)

If your issue relates to:
- **flagship design skill (craft/teach/extract modes) — start here** — check `impeccable` if appropriate.
- **generate Stitch-friendly DESIGN.md taste standard (Stitch first-pass)** — check `stitch-design-taste` if appropriate.
- **plan UX/UI for a feature before writing code (design brief)** — check `ux-design-brief` if appropriate.
- **mirror shadcn implementation patterns source-by-source** — check `shadcn-parity` if appropriate.
- **LAST-RESORT heavyweight reference (50+ styles, 161 palettes, etc.)** — check `ui-ux-pro-max` if appropriate.
- **strip designs to essence; declutter** — check `distill` if appropriate.
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


---

# Quieter mode (tone down intensity)


## ⚡ Stitch-First Mandate (read before doing anything else)

ALWAYS send a draft of your proposals with artifacts to **Stitch** as a first attempt — before generating final code. Stitch (Google's screen-generation AI at `labs.google.com/stitch`) produces a baseline that grounds your taste against the curated design system in `STITCH-DESIGN.md` (in this folder).

Workflow:

1. **Draft locally** — sketch the proposal: intent, layout, palette, motion, components.
2. **Hand off to Stitch first** — paste the draft + relevant `STITCH-DESIGN.md` rules into a Stitch prompt. Capture the artifact (screen/component) Stitch returns.
3. **Critique the Stitch artifact** against this skill's specific lens (the section below). Note what works, what's generic, what needs more intent.
4. **Then produce final code** — using the Stitch artifact as the visual anchor, refined through this skill's rules.

The reference design language lives in `STITCH-DESIGN.md` next to this file. Read it before writing the Stitch prompt — it encodes the anti-generic taste standard (typography, color, asymmetry, micro-motion).



Reduce visual intensity in designs that are too bold, aggressive, or overstimulating, creating a more refined and approachable aesthetic without losing effectiveness.

## MANDATORY PREPARATION

Invoke /impeccable — it contains design principles, anti-patterns, and the **Context Gathering Protocol**. Follow the protocol before proceeding — if no design context exists yet, you MUST run /impeccable teach first.


## Assess Current State

Analyze what makes the design feel too intense:

1. **Identify intensity sources**:
   - **Color saturation**: Overly bright or saturated colors
   - **Contrast extremes**: Too much high-contrast juxtaposition
   - **Visual weight**: Too many bold, heavy elements competing
   - **Animation excess**: Too much motion or overly dramatic effects
   - **Complexity**: Too many visual elements, patterns, or decorations
   - **Scale**: Everything is large and loud with no hierarchy

2. **Understand the context**:
   - What's the purpose? (Marketing vs tool vs reading experience)
   - Who's the audience? (Some contexts need energy)
   - What's working? (Don't throw away good ideas)
   - What's the core message? (Preserve what matters)

If any of these are unclear from the codebase, ask the user directly to clarify what you cannot infer.

**CRITICAL**: "Quieter" doesn't mean boring or generic. It means refined, sophisticated, and easier on the eyes. Think luxury, not laziness.

## Plan Refinement

Create a strategy to reduce intensity while maintaining impact:

- **Color approach**: Desaturate or shift to more sophisticated tones?
- **Hierarchy approach**: Which elements should stay bold (very few), which should recede?
- **Simplification approach**: What can be removed entirely?
- **Sophistication approach**: How can we signal quality through restraint?

**IMPORTANT**: Great quiet design is harder than great bold design. Subtlety requires precision.

## Refine the Design

Systematically reduce intensity across these dimensions:

### Color Refinement
- **Reduce saturation**: Shift from fully saturated to 70-85% saturation
- **Soften palette**: Replace bright colors with muted, sophisticated tones
- **Reduce color variety**: Use fewer colors more thoughtfully
- **Neutral dominance**: Let neutrals do more work, use color as accent (10% rule)
- **Gentler contrasts**: High contrast only where it matters most
- **Tinted grays**: Use warm or cool tinted grays instead of pure gray—adds sophistication without loudness
- **Never gray on color**: If you have gray text on a colored background, use a darker shade of that color or transparency instead

### Visual Weight Reduction
- **Typography**: Reduce font weights (900 → 600, 700 → 500), decrease sizes where appropriate
- **Hierarchy through subtlety**: Use weight, size, and space instead of color and boldness
- **White space**: Increase breathing room, reduce density
- **Borders & lines**: Reduce thickness, decrease opacity, or remove entirely

### Simplification
- **Remove decorative elements**: Gradients, shadows, patterns, textures that don't serve purpose
- **Simplify shapes**: Reduce border radius extremes, simplify custom shapes
- **Reduce layering**: Flatten visual hierarchy where possible
- **Clean up effects**: Reduce or remove blur effects, glows, multiple shadows

### Motion Reduction
- **Reduce animation intensity**: Shorter distances (10-20px instead of 40px), gentler easing
- **Remove decorative animations**: Keep functional motion, remove flourishes
- **Subtle micro-interactions**: Replace dramatic effects with gentle feedback
- **Refined easing**: Use ease-out-quart for smooth, understated motion—never bounce or elastic
- **Remove animations entirely** if they're not serving a clear purpose

### Composition Refinement
- **Reduce scale jumps**: Smaller contrast between sizes creates calmer feeling
- **Align to grid**: Bring rogue elements back into systematic alignment
- **Even out spacing**: Replace extreme spacing variations with consistent rhythm

**NEVER**:
- Make everything the same size/weight (hierarchy still matters)
- Remove all color (quiet ≠ grayscale)
- Eliminate all personality (maintain character through refinement)
- Sacrifice usability for aesthetics (functional elements still need clear affordances)
- Make everything small and light (some anchors needed)

## Verify Quality

Ensure refinement maintains quality:

- **Still functional**: Can users still accomplish tasks easily?
- **Still distinctive**: Does it have character, or is it generic now?
- **Better reading**: Is text easier to read for extended periods?
- **Sophistication**: Does it feel more refined and premium?

Remember: Quiet design is confident design. It doesn't need to shout. Less is more, but less is also harder. Refine with precision and maintain intentionality.

<!-- cross-ref:start -->

## See also (related skills — Design family)

If your issue relates to:
- **flagship design skill (craft/teach/extract modes) — start here** — check `impeccable` if appropriate.
- **generate Stitch-friendly DESIGN.md taste standard (Stitch first-pass)** — check `stitch-design-taste` if appropriate.
- **plan UX/UI for a feature before writing code (design brief)** — check `ux-design-brief` if appropriate.
- **mirror shadcn implementation patterns source-by-source** — check `shadcn-parity` if appropriate.
- **LAST-RESORT heavyweight reference (50+ styles, 161 palettes, etc.)** — check `ui-ux-pro-max` if appropriate.
- **strip designs to essence; declutter** — check `distill` if appropriate.
- **final quality pass — alignment, spacing, consistency** — check `polish` if appropriate.
- **add moments of joy, micro-interactions, personality** — check `delight` if appropriate.
- **score the design with UX-grade feedback** — check `critique` if appropriate.
- **amplify bland/safe designs** — check `bolder` if appropriate.
- **go all-out — shaders, springs, scroll-driven reveals** — check `overdrive` if appropriate.
- **interaction motion and transitions** — check `animate` if appropriate.
- **responsive design across viewports** — check `adapt` if appropriate.
- **typography — fonts, hierarchy, size, weight** — check `typeset` if appropriate.
- **spacing, grids, visual rhythm** — check `layout` if appropriate.
- **color systems** — check `colorize` if appropriate.
- **performance — load time, bundle, jank** — check `optimize` if appropriate.

<!-- cross-ref:end -->

