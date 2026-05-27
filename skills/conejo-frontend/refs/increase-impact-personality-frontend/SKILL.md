---
name: increase-impact-personality-frontend
description: Amplify a frontend design's impact, boldness, and personality. Three modes — Overdrive (technically ambitious, shaders/spring physics/scroll-driven, "wow"), Bolder (turn bland/safe into striking while keeping usability), and Delight (joyful micro-interactions, unexpected touches, memorable moments). Use when the user wants the UI to feel more, not less — "too boring", "too safe", "bland", "make it pop", "wow me", "go all-out".
---

# Increase Impact / Personality / Frontend

Three modes for adding intensity to an interface — pick the right dial.

| Mode | When |
|---|---|
| **Overdrive** | Go all-out — shaders, spring physics, scroll-driven reveals, 60fps animations, cinematic transitions |
| **Bolder** | Take bland/safe/generic up a notch while preserving usability |
| **Delight** | Add joyful micro-interactions and unexpected touches that make the UI memorable |

If unsure which: **Delight** is the safest, **Bolder** is the workhorse, **Overdrive** is the high-risk-high-reward swing.


---

# Overdrive mode (go all-out)


## ⚡ Stitch-First Mandate (read before doing anything else)

ALWAYS send a draft of your proposals with artifacts to **Stitch** as a first attempt — before generating final code. Stitch (Google's screen-generation AI at `labs.google.com/stitch`) produces a baseline that grounds your taste against the curated design system in `STITCH-DESIGN.md` (in this folder).

Workflow:

1. **Draft locally** — sketch the proposal: intent, layout, palette, motion, components.
2. **Hand off to Stitch first** — paste the draft + relevant `STITCH-DESIGN.md` rules into a Stitch prompt. Capture the artifact (screen/component) Stitch returns.
3. **Critique the Stitch artifact** against this skill's specific lens (the section below). Note what works, what's generic, what needs more intent.
4. **Then produce final code** — using the Stitch artifact as the visual anchor, refined through this skill's rules.

The reference design language lives in `STITCH-DESIGN.md` next to this file. Read it before writing the Stitch prompt — it encodes the anti-generic taste standard (typography, color, asymmetry, micro-motion).



Start your response with:

```
──────────── ⚡ OVERDRIVE ─────────────
》》》 Entering overdrive mode...
```

Push an interface past conventional limits. This isn't just about visual effects — it's about using the full power of the browser to make any part of an interface feel extraordinary: a table that handles a million rows, a dialog that morphs from its trigger, a form that validates in real-time with streaming feedback, a page transition that feels cinematic.

## MANDATORY PREPARATION

Invoke /impeccable — it contains design principles, anti-patterns, and the **Context Gathering Protocol**. Follow the protocol before proceeding — if no design context exists yet, you MUST run /impeccable teach first.

**EXTRA IMPORTANT FOR THIS SKILL**: Context determines what "extraordinary" means. A particle system on a creative portfolio is impressive. The same particle system on a settings page is embarrassing. But a settings page with instant optimistic saves and animated state transitions? That's extraordinary too. Understand the project's personality and goals before deciding what's appropriate.

### Propose Before Building

This skill has the highest potential to misfire. Do NOT jump straight into implementation. You MUST:

1. **Think through 2-3 different directions** — consider different techniques, levels of ambition, and aesthetic approaches. For each direction, briefly describe what the result would look and feel like.
2. **ask the user directly to clarify what you cannot infer.** to present these directions and get the user's pick before writing any code. Explain trade-offs (browser support, performance cost, complexity).
3. Only proceed with the direction the user confirms.

Skipping this step risks building something embarrassing that needs to be thrown away.

### Iterate with Browser Automation

Technically ambitious effects almost never work on the first try. You MUST actively use browser automation tools to preview your work, visually verify the result, and iterate. Do not assume the effect looks right — check it. Expect multiple rounds of refinement. The gap between "technically works" and "looks extraordinary" is closed through visual iteration, not code alone.


## Assess What "Extraordinary" Means Here

The right kind of technical ambition depends entirely on what you're working with. Before choosing a technique, ask: **what would make a user of THIS specific interface say "wow, that's nice"?**

### For visual/marketing surfaces
Pages, hero sections, landing pages, portfolios — the "wow" is often sensory: a scroll-driven reveal, a shader background, a cinematic page transition, generative art that responds to the cursor.

### For functional UI
Tables, forms, dialogs, navigation — the "wow" is in how it FEELS: a dialog that morphs from the button that triggered it via View Transitions, a data table that renders 100k rows at 60fps via virtual scrolling, a form with streaming validation that feels instant, drag-and-drop with spring physics.

### For performance-critical UI
The "wow" is invisible but felt: a search that filters 50k items without a flicker, a complex form that never blocks the main thread, an image editor that processes in near-real-time. The interface just never hesitates.

### For data-heavy interfaces
Charts and dashboards — the "wow" is in fluidity: GPU-accelerated rendering via Canvas/WebGL for massive datasets, animated transitions between data states, force-directed graph layouts that settle naturally.

**The common thread**: something about the implementation goes beyond what users expect from a web interface. The technique serves the experience, not the other way around.

## The Toolkit

Organized by what you're trying to achieve, not by technology name.

### Make transitions feel cinematic
- **View Transitions API** (same-document: all browsers; cross-document: no Firefox) — shared element morphing between states. A list item expanding into a detail page. A button morphing into a dialog. This is the closest thing to native FLIP animations.
- **`@starting-style`** (all browsers) — animate elements from `display: none` to visible with CSS only, including entry keyframes
- **Spring physics** — natural motion with mass, tension, and damping instead of cubic-bezier. Libraries: motion (formerly Framer Motion), GSAP, or roll your own spring solver.

### Tie animation to scroll position
- **Scroll-driven animations** (`animation-timeline: scroll()`) — CSS-only, no JS. Parallax, progress bars, reveal sequences all driven by scroll position. (Chrome/Edge/Safari; Firefox: flag only — always provide a static fallback)

### Render beyond CSS
- **WebGL** (all browsers) — shader effects, post-processing, particle systems. Libraries: Three.js, OGL (lightweight), regl. Use for effects CSS can't express.
- **WebGPU** (Chrome/Edge; Safari partial; Firefox: flag only) — next-gen GPU compute. More powerful than WebGL but limited browser support. Always fall back to WebGL2.
- **Canvas 2D / OffscreenCanvas** — custom rendering, pixel manipulation, or moving heavy rendering off the main thread entirely via Web Workers + OffscreenCanvas.
- **SVG filter chains** — displacement maps, turbulence, morphology for organic distortion effects. CSS-animatable.

### Make data feel alive
- **Virtual scrolling** — render only visible rows for tables/lists with tens of thousands of items. No library required for simple cases; TanStack Virtual for complex ones.
- **GPU-accelerated charts** — Canvas or WebGL-rendered data visualization for datasets too large for SVG/DOM. Libraries: deck.gl, regl-based custom renderers.
- **Animated data transitions** — morph between chart states rather than replacing. D3's `transition()` or View Transitions for DOM-based charts.

### Animate complex properties
- **`@property`** (all browsers) — register custom CSS properties with types, enabling animation of gradients, colors, and complex values that CSS can't normally interpolate.
- **Web Animations API** (all browsers) — JavaScript-driven animations with the performance of CSS. Composable, cancellable, reversible. The foundation for complex choreography.

### Push performance boundaries
- **Web Workers** — move computation off the main thread. Heavy data processing, image manipulation, search indexing — anything that would cause jank.
- **OffscreenCanvas** — render in a Worker thread. The main thread stays free while complex visuals render in the background.
- **WASM** — near-native performance for computation-heavy features. Image processing, physics simulations, codecs.

### Interact with the device
- **Web Audio API** — spatial audio, audio-reactive visualizations, sonic feedback. Requires user gesture to start.
- **Device APIs** — orientation, ambient light, geolocation. Use sparingly and always with user permission.

**NOTE**: This skill is about enhancing how an interface FEELS, not changing what a product DOES. Adding real-time collaboration, offline support, or new backend capabilities are product decisions, not UI enhancements. Focus on making existing features feel extraordinary.

## Implement with Discipline

### Progressive enhancement is non-negotiable

Every technique must degrade gracefully. The experience without the enhancement must still be good.

```css
@supports (animation-timeline: scroll()) {
  .hero { animation-timeline: scroll(); }
}
```

```javascript
if ('gpu' in navigator) { /* WebGPU */ }
else if (canvas.getContext('webgl2')) { /* WebGL2 fallback */ }
/* CSS-only fallback must still look good */
```

### Performance rules

- Target 60fps. If dropping below 50, simplify.
- Respect `prefers-reduced-motion` — always. Provide a beautiful static alternative.
- Lazy-initialize heavy resources (WebGL contexts, WASM modules) only when near viewport.
- Pause off-screen rendering. Kill what you can't see.
- Test on real mid-range devices, not just your development machine.

### Polish is the difference

The gap between "cool" and "extraordinary" is in the last 20% of refinement: the easing curve on a spring animation, the timing offset in a staggered reveal, the subtle secondary motion that makes a transition feel physical. Don't ship the first version that works — ship the version that feels inevitable.

**NEVER**:
- Ignore `prefers-reduced-motion` — this is an accessibility requirement, not a suggestion
- Ship effects that cause jank on mid-range devices
- Use bleeding-edge APIs without a functional fallback
- Add sound without explicit user opt-in
- Use technical ambition to mask weak design fundamentals — fix those first with other skills
- Layer multiple competing extraordinary moments — focus creates impact, excess creates noise

## Verify the Result

- **The wow test**: Show it to someone who hasn't seen it. Do they react?
- **The removal test**: Take it away. Does the experience feel diminished, or does nobody notice?
- **The device test**: Run it on a phone, a tablet, a Chromebook. Still smooth?
- **The accessibility test**: Enable reduced motion. Still beautiful?
- **The context test**: Does this make sense for THIS brand and audience?

Remember: "Technically extraordinary" isn't about using the newest API. It's about making an interface do something users didn't think a website could do.

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
- **tone down overly bold or aggressive designs** — check `quieter` if appropriate.
- **amplify bland/safe designs** — check `bolder` if appropriate.
- **interaction motion and transitions** — check `animate` if appropriate.
- **responsive design across viewports** — check `adapt` if appropriate.
- **typography — fonts, hierarchy, size, weight** — check `typeset` if appropriate.
- **spacing, grids, visual rhythm** — check `layout` if appropriate.
- **color systems** — check `colorize` if appropriate.
- **performance — load time, bundle, jank** — check `optimize` if appropriate.

<!-- cross-ref:end -->


---

# Bolder mode (amplify safe designs)


## ⚡ Stitch-First Mandate (read before doing anything else)

ALWAYS send a draft of your proposals with artifacts to **Stitch** as a first attempt — before generating final code. Stitch (Google's screen-generation AI at `labs.google.com/stitch`) produces a baseline that grounds your taste against the curated design system in `STITCH-DESIGN.md` (in this folder).

Workflow:

1. **Draft locally** — sketch the proposal: intent, layout, palette, motion, components.
2. **Hand off to Stitch first** — paste the draft + relevant `STITCH-DESIGN.md` rules into a Stitch prompt. Capture the artifact (screen/component) Stitch returns.
3. **Critique the Stitch artifact** against this skill's specific lens (the section below). Note what works, what's generic, what needs more intent.
4. **Then produce final code** — using the Stitch artifact as the visual anchor, refined through this skill's rules.

The reference design language lives in `STITCH-DESIGN.md` next to this file. Read it before writing the Stitch prompt — it encodes the anti-generic taste standard (typography, color, asymmetry, micro-motion).



Increase visual impact and personality in designs that are too safe, generic, or visually underwhelming, creating more engaging and memorable experiences.

## MANDATORY PREPARATION

Invoke /impeccable — it contains design principles, anti-patterns, and the **Context Gathering Protocol**. Follow the protocol before proceeding — if no design context exists yet, you MUST run /impeccable teach first.


## Assess Current State

Analyze what makes the design feel too safe or boring:

1. **Identify weakness sources**:
   - **Generic choices**: System fonts, basic colors, standard layouts
   - **Timid scale**: Everything is medium-sized with no drama
   - **Low contrast**: Everything has similar visual weight
   - **Static**: No motion, no energy, no life
   - **Predictable**: Standard patterns with no surprises
   - **Flat hierarchy**: Nothing stands out or commands attention

2. **Understand the context**:
   - What's the brand personality? (How far can we push?)
   - What's the purpose? (Marketing can be bolder than financial dashboards)
   - Who's the audience? (What will resonate?)
   - What are the constraints? (Brand guidelines, accessibility, performance)

If any of these are unclear from the codebase, ask the user directly to clarify what you cannot infer.

**CRITICAL**: "Bolder" doesn't mean chaotic or garish. It means distinctive, memorable, and confident. Think intentional drama, not random chaos.

**WARNING - AI SLOP TRAP**: When making things "bolder," AI defaults to the same tired tricks: cyan/purple gradients, glassmorphism, neon accents on dark backgrounds, gradient text on metrics. These are the OPPOSITE of bold—they're generic. Review ALL the DON'T guidelines in the impeccable skill before proceeding. Bold means distinctive, not "more effects."

## Plan Amplification

Create a strategy to increase impact while maintaining coherence:

- **Focal point**: What should be the hero moment? (Pick ONE, make it amazing)
- **Personality direction**: Maximalist chaos? Elegant drama? Playful energy? Dark moody? Choose a lane.
- **Risk budget**: How experimental can we be? Push boundaries within constraints.
- **Hierarchy amplification**: Make big things BIGGER, small things smaller (increase contrast)

**IMPORTANT**: Bold design must still be usable. Impact without function is just decoration.

## Amplify the Design

Systematically increase impact across these dimensions:

### Typography Amplification
- **Replace generic fonts**: Swap system fonts for distinctive choices (see impeccable skill for inspiration)
- **Extreme scale**: Create dramatic size jumps (3x-5x differences, not 1.5x)
- **Weight contrast**: Pair 900 weights with 200 weights, not 600 with 400
- **Unexpected choices**: Variable fonts, display fonts for headlines, condensed/extended widths, monospace as intentional accent (not as lazy "dev tool" default)

### Color Intensification
- **Increase saturation**: Shift to more vibrant, energetic colors (but not neon)
- **Bold palette**: Introduce unexpected color combinations—avoid the purple-blue gradient AI slop
- **Dominant color strategy**: Let one bold color own 60% of the design
- **Sharp accents**: High-contrast accent colors that pop
- **Tinted neutrals**: Replace pure grays with tinted grays that harmonize with your palette
- **Rich gradients**: Intentional multi-stop gradients (not generic purple-to-blue)

### Spatial Drama
- **Extreme scale jumps**: Make important elements 3-5x larger than surroundings
- **Break the grid**: Let hero elements escape containers and cross boundaries
- **Asymmetric layouts**: Replace centered, balanced layouts with tension-filled asymmetry
- **Generous space**: Use white space dramatically (100-200px gaps, not 20-40px)
- **Overlap**: Layer elements intentionally for depth

### Visual Effects
- **Dramatic shadows**: Large, soft shadows for elevation (but not generic drop shadows on rounded rectangles)
- **Background treatments**: Mesh patterns, noise textures, geometric patterns, intentional gradients (not purple-to-blue)
- **Texture & depth**: Grain, halftone, duotone, layered elements—NOT glassmorphism (it's overused AI slop)
- **Borders & frames**: Thick borders, decorative frames, custom shapes (not rounded rectangles with colored border on one side)
- **Custom elements**: Illustrative elements, custom icons, decorative details that reinforce brand

### Motion & Animation
- **Entrance choreography**: Staggered, dramatic page load animations with 50-100ms delays
- **Scroll effects**: Parallax, reveal animations, scroll-triggered sequences
- **Micro-interactions**: Satisfying hover effects, click feedback, state changes
- **Transitions**: Smooth, noticeable transitions using ease-out-quart/quint/expo (not bounce or elastic—they cheapen the effect)

### Composition Boldness
- **Hero moments**: Create clear focal points with dramatic treatment
- **Diagonal flows**: Escape horizontal/vertical rigidity with diagonal arrangements
- **Full-bleed elements**: Use full viewport width/height for impact
- **Unexpected proportions**: Golden ratio? Throw it out. Try 70/30, 80/20 splits

**NEVER**:
- Add effects randomly without purpose (chaos ≠ bold)
- Sacrifice readability for aesthetics (body text must be readable)
- Make everything bold (then nothing is bold - need contrast)
- Ignore accessibility (bold design must still meet WCAG standards)
- Overwhelm with motion (animation fatigue is real)
- Copy trendy aesthetics blindly (bold means distinctive, not derivative)

## Verify Quality

Ensure amplification maintains usability and coherence:

- **NOT AI slop**: Does this look like every other AI-generated "bold" design? If yes, start over.
- **Still functional**: Can users accomplish tasks without distraction?
- **Coherent**: Does everything feel intentional and unified?
- **Memorable**: Will users remember this experience?
- **Performant**: Do all these effects run smoothly?
- **Accessible**: Does it still meet accessibility standards?

**The test**: If you showed this to someone and said "AI made this bolder," would they believe you immediately? If yes, you've failed. Bold means distinctive, not "more AI effects."

Remember: Bold design is confident design. It takes risks, makes statements, and creates memorable experiences. But bold without strategy is just loud. Be intentional, be dramatic, be unforgettable.

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
- **tone down overly bold or aggressive designs** — check `quieter` if appropriate.
- **go all-out — shaders, springs, scroll-driven reveals** — check `overdrive` if appropriate.
- **interaction motion and transitions** — check `animate` if appropriate.
- **responsive design across viewports** — check `adapt` if appropriate.
- **typography — fonts, hierarchy, size, weight** — check `typeset` if appropriate.
- **spacing, grids, visual rhythm** — check `layout` if appropriate.
- **color systems** — check `colorize` if appropriate.
- **performance — load time, bundle, jank** — check `optimize` if appropriate.

<!-- cross-ref:end -->


---

# Delight mode (joy, personality, micro-interactions)


## ⚡ Stitch-First Mandate (read before doing anything else)

ALWAYS send a draft of your proposals with artifacts to **Stitch** as a first attempt — before generating final code. Stitch (Google's screen-generation AI at `labs.google.com/stitch`) produces a baseline that grounds your taste against the curated design system in `STITCH-DESIGN.md` (in this folder).

Workflow:

1. **Draft locally** — sketch the proposal: intent, layout, palette, motion, components.
2. **Hand off to Stitch first** — paste the draft + relevant `STITCH-DESIGN.md` rules into a Stitch prompt. Capture the artifact (screen/component) Stitch returns.
3. **Critique the Stitch artifact** against this skill's specific lens (the section below). Note what works, what's generic, what needs more intent.
4. **Then produce final code** — using the Stitch artifact as the visual anchor, refined through this skill's rules.

The reference design language lives in `STITCH-DESIGN.md` next to this file. Read it before writing the Stitch prompt — it encodes the anti-generic taste standard (typography, color, asymmetry, micro-motion).



Identify opportunities to add moments of joy, personality, and unexpected polish that transform functional interfaces into delightful experiences.

## MANDATORY PREPARATION

Invoke /impeccable — it contains design principles, anti-patterns, and the **Context Gathering Protocol**. Follow the protocol before proceeding — if no design context exists yet, you MUST run /impeccable teach first. Additionally gather: what's appropriate for the domain (playful vs professional vs quirky vs elegant).


## Assess Delight Opportunities

Identify where delight would enhance (not distract from) the experience:

1. **Find natural delight moments**:
   - **Success states**: Completed actions (save, send, publish)
   - **Empty states**: First-time experiences, onboarding
   - **Loading states**: Waiting periods that could be entertaining
   - **Achievements**: Milestones, streaks, completions
   - **Interactions**: Hover states, clicks, drags
   - **Errors**: Softening frustrating moments
   - **Easter eggs**: Hidden discoveries for curious users

2. **Understand the context**:
   - What's the brand personality? (Playful? Professional? Quirky? Elegant?)
   - Who's the audience? (Tech-savvy? Creative? Corporate?)
   - What's the emotional context? (Accomplishment? Exploration? Frustration?)
   - What's appropriate? (Banking app ≠ gaming app)

3. **Define delight strategy**:
   - **Subtle sophistication**: Refined micro-interactions (luxury brands)
   - **Playful personality**: Whimsical illustrations and copy (consumer apps)
   - **Helpful surprises**: Anticipating needs before users ask (productivity tools)
   - **Sensory richness**: Satisfying sounds, smooth animations (creative tools)

If any of these are unclear from the codebase, ask the user directly to clarify what you cannot infer.

**CRITICAL**: Delight should enhance usability, never obscure it. If users notice the delight more than accomplishing their goal, you've gone too far.

## Delight Principles

Follow these guidelines:

### Delight Amplifies, Never Blocks
- Delight moments should be quick (< 1 second)
- Never delay core functionality for delight
- Make delight skippable or subtle
- Respect user's time and task focus

### Surprise and Discovery
- Hide delightful details for users to discover
- Reward exploration and curiosity
- Don't announce every delight moment
- Let users share discoveries with others

### Appropriate to Context
- Match delight to emotional moment (celebrate success, empathize with errors)
- Respect the user's state (don't be playful during critical errors)
- Match brand personality and audience expectations
- Cultural sensitivity (what's delightful varies by culture)

### Compound Over Time
- Delight should remain fresh with repeated use
- Vary responses (not same animation every time)
- Reveal deeper layers with continued use
- Build anticipation through patterns

## Delight Techniques

Add personality and joy through these methods:

### Micro-interactions & Animation

**Button delight**:
```css
/* Satisfying button press */
.button {
  transition: transform 0.1s, box-shadow 0.1s;
}
.button:active {
  transform: translateY(2px);
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

/* Ripple effect on click */
/* Smooth lift on hover */
.button:hover {
  transform: translateY(-2px);
  transition: transform 0.2s cubic-bezier(0.25, 1, 0.5, 1); /* ease-out-quart */
}
```

**Loading delight**:
- Playful loading animations (not just spinners)
- Personality in loading messages (write product-specific ones, not generic AI filler)
- Progress indication with encouraging messages
- Skeleton screens with subtle animations

**Success animations**:
- Checkmark draw animation
- Confetti burst for major achievements
- Gentle scale + fade for confirmation
- Satisfying sound effects (subtle)

**Hover surprises**:
- Icons that animate on hover
- Color shifts or glow effects
- Tooltip reveals with personality
- Cursor changes (custom cursors for branded experiences)

### Personality in Copy

**Playful error messages**:
```
"Error 404"
"This page is playing hide and seek. (And winning)"

"Connection failed"
"Looks like the internet took a coffee break. Want to retry?"
```

**Encouraging empty states**:
```
"No projects"
"Your canvas awaits. Create something amazing."

"No messages"
"Inbox zero! You're crushing it today."
```

**Playful labels & tooltips**:
```
"Delete"
"Send to void" (for playful brand)

"Help"
"Rescue me" (tooltip)
```

**IMPORTANT**: Match copy personality to brand. Banks shouldn't be wacky, but they can be warm.

### Illustrations & Visual Personality

**Custom illustrations**:
- Empty state illustrations (not stock icons)
- Error state illustrations (friendly monsters, quirky characters)
- Loading state illustrations (animated characters)
- Success state illustrations (celebrations)

**Icon personality**:
- Custom icon set matching brand personality
- Animated icons (subtle motion on hover/click)
- Illustrative icons (more detailed than generic)
- Consistent style across all icons

**Background effects**:
- Subtle particle effects
- Gradient mesh backgrounds
- Geometric patterns
- Parallax depth
- Time-of-day themes (morning vs night)

### Satisfying Interactions

**Drag and drop delight**:
- Lift effect on drag (shadow, scale)
- Snap animation when dropped
- Satisfying placement sound
- Undo toast ("Dropped in wrong place? [Undo]")

**Toggle switches**:
- Smooth slide with spring physics
- Color transition
- Haptic feedback on mobile
- Optional sound effect

**Progress & achievements**:
- Streak counters with celebratory milestones
- Progress bars that "celebrate" at 100%
- Badge unlocks with animation
- Playful stats ("You're on fire! 5 days in a row")

**Form interactions**:
- Input fields that animate on focus
- Checkboxes with a satisfying scale pulse when checked
- Success state that celebrates valid input
- Auto-grow textareas

### Sound Design

**Subtle audio cues** (when appropriate):
- Notification sounds (distinctive but not annoying)
- Success sounds (satisfying "ding")
- Error sounds (empathetic, not harsh)
- Typing sounds for chat/messaging
- Ambient background audio (very subtle)

**IMPORTANT**:
- Respect system sound settings
- Provide mute option
- Keep volumes quiet (subtle cues, not alarms)
- Don't play on every interaction (sound fatigue is real)

### Easter Eggs & Hidden Delights

**Discovery rewards**:
- Konami code unlocks special theme
- Hidden keyboard shortcuts (Cmd+K for special features)
- Hover reveals on logos or illustrations
- Alt text jokes on images (for screen reader users too!)
- Console messages for developers ("Like what you see? We're hiring!")

**Seasonal touches**:
- Holiday themes (subtle, tasteful)
- Seasonal color shifts
- Weather-based variations
- Time-based changes (dark at night, light during day)

**Contextual personality**:
- Different messages based on time of day
- Responses to specific user actions
- Randomized variations (not same every time)
- Progressive reveals with continued use

### Loading & Waiting States

**Make waiting engaging**:
- Interesting loading messages that rotate
- Progress bars with personality
- Mini-games during long loads
- Fun facts or tips while waiting
- Countdown with encouraging messages

```
Loading messages — write ones specific to your product, not generic AI filler:
- "Crunching your latest numbers..."
- "Syncing with your team's changes..."
- "Preparing your dashboard..."
- "Checking for updates since yesterday..."
```

**WARNING**: Avoid cliched loading messages like "Herding pixels", "Teaching robots to dance", "Consulting the magic 8-ball", "Counting backwards from infinity". These are AI-slop copy — instantly recognizable as machine-generated. Write messages that are specific to what your product actually does.

### Celebration Moments

**Success celebrations**:
- Confetti for major milestones
- Animated checkmarks for completions
- Progress bar celebrations at 100%
- "Achievement unlocked" style notifications
- Personalized messages ("You published your 10th article!")

**Milestone recognition**:
- First-time actions get special treatment
- Streak tracking and celebration
- Progress toward goals
- Anniversary celebrations

## Implementation Patterns

**Animation libraries**:
- Framer Motion (React)
- GSAP (universal)
- Lottie (After Effects animations)
- Canvas confetti (party effects)

**Sound libraries**:
- Howler.js (audio management)
- Use-sound (React hook)

**Physics libraries**:
- React Spring (spring physics)
- Popmotion (animation primitives)

**IMPORTANT**: File size matters. Compress images, optimize animations, lazy load delight features.

**NEVER**:
- Delay core functionality for delight
- Force users through delightful moments (make skippable)
- Use delight to hide poor UX
- Overdo it (less is more)
- Ignore accessibility (animate responsibly, provide alternatives)
- Make every interaction delightful (special moments should be special)
- Sacrifice performance for delight
- Be inappropriate for context (read the room)

## Verify Delight Quality

Test that delight actually delights:

- **User reactions**: Do users smile? Share screenshots?
- **Doesn't annoy**: Still pleasant after 100th time?
- **Doesn't block**: Can users opt out or skip?
- **Performant**: No jank, no slowdown
- **Appropriate**: Matches brand and context
- **Accessible**: Works with reduced motion, screen readers

Remember: Delight is the difference between a tool and an experience. Add personality, surprise users positively, and create moments worth sharing. But always respect usability - delight should enhance, never obstruct.

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

# Animate mode (purposeful motion & micro-interactions)

_Merged from former `animate` skill — motion is one of the strongest personality dials._


## ⚡ Stitch-First Mandate (read before doing anything else)

ALWAYS send a draft of your proposals with artifacts to **Stitch** as a first attempt — before generating final code. Stitch (Google's screen-generation AI at `labs.google.com/stitch`) produces a baseline that grounds your taste against the curated design system in `STITCH-DESIGN.md` (in this folder).

Workflow:

1. **Draft locally** — sketch the proposal: intent, layout, palette, motion, components.
2. **Hand off to Stitch first** — paste the draft + relevant `STITCH-DESIGN.md` rules into a Stitch prompt. Capture the artifact (screen/component) Stitch returns.
3. **Critique the Stitch artifact** against this skill's specific lens (the section below). Note what works, what's generic, what needs more intent.
4. **Then produce final code** — using the Stitch artifact as the visual anchor, refined through this skill's rules.

The reference design language lives in `STITCH-DESIGN.md` next to this file. Read it before writing the Stitch prompt — it encodes the anti-generic taste standard (typography, color, asymmetry, micro-motion).



Analyze a feature and strategically add animations and micro-interactions that enhance understanding, provide feedback, and create delight.

## MANDATORY PREPARATION

Invoke /impeccable — it contains design principles, anti-patterns, and the **Context Gathering Protocol**. Follow the protocol before proceeding — if no design context exists yet, you MUST run /impeccable teach first. Additionally gather: performance constraints.


## Assess Animation Opportunities

Analyze where motion would improve the experience:

1. **Identify static areas**:
   - **Missing feedback**: Actions without visual acknowledgment (button clicks, form submission, etc.)
   - **Jarring transitions**: Instant state changes that feel abrupt (show/hide, page loads, route changes)
   - **Unclear relationships**: Spatial or hierarchical relationships that aren't obvious
   - **Lack of delight**: Functional but joyless interactions
   - **Missed guidance**: Opportunities to direct attention or explain behavior

2. **Understand the context**:
   - What's the personality? (Playful vs serious, energetic vs calm)
   - What's the performance budget? (Mobile-first? Complex page?)
   - Who's the audience? (Motion-sensitive users? Power users who want speed?)
   - What matters most? (One hero animation vs many micro-interactions?)

If any of these are unclear from the codebase, ask the user directly to clarify what you cannot infer.

**CRITICAL**: Respect `prefers-reduced-motion`. Always provide non-animated alternatives for users who need them.

## Plan Animation Strategy

Create a purposeful animation plan:

- **Hero moment**: What's the ONE signature animation? (Page load? Hero section? Key interaction?)
- **Feedback layer**: Which interactions need acknowledgment?
- **Transition layer**: Which state changes need smoothing?
- **Delight layer**: Where can we surprise and delight?

**IMPORTANT**: One well-orchestrated experience beats scattered animations everywhere. Focus on high-impact moments.

## Implement Animations

Add motion systematically across these categories:

### Entrance Animations
- **Page load choreography**: Stagger element reveals (100-150ms delays), fade + slide combinations
- **Hero section**: Dramatic entrance for primary content (scale, parallax, or creative effects)
- **Content reveals**: Scroll-triggered animations using intersection observer
- **Modal/drawer entry**: Smooth slide + fade, backdrop fade, focus management

### Micro-interactions
- **Button feedback**:
  - Hover: Subtle scale (1.02-1.05), color shift, shadow increase
  - Click: Quick scale down then up (0.95 → 1), ripple effect
  - Loading: Spinner or pulse state
- **Form interactions**:
  - Input focus: Border color transition, slight scale or glow
  - Validation: Shake on error, check mark on success, smooth color transitions
- **Toggle switches**: Smooth slide + color transition (200-300ms)
- **Checkboxes/radio**: Check mark animation, ripple effect
- **Like/favorite**: Scale + rotation, particle effects, color transition

### State Transitions
- **Show/hide**: Fade + slide (not instant), appropriate timing (200-300ms)
- **Expand/collapse**: Height transition with overflow handling, icon rotation
- **Loading states**: Skeleton screen fades, spinner animations, progress bars
- **Success/error**: Color transitions, icon animations, gentle scale pulse
- **Enable/disable**: Opacity transitions, cursor changes

### Navigation & Flow
- **Page transitions**: Crossfade between routes, shared element transitions
- **Tab switching**: Slide indicator, content fade/slide
- **Carousel/slider**: Smooth transforms, snap points, momentum
- **Scroll effects**: Parallax layers, sticky headers with state changes, scroll progress indicators

### Feedback & Guidance
- **Hover hints**: Tooltip fade-ins, cursor changes, element highlights
- **Drag & drop**: Lift effect (shadow + scale), drop zone highlights, smooth repositioning
- **Copy/paste**: Brief highlight flash on paste, "copied" confirmation
- **Focus flow**: Highlight path through form or workflow

### Delight Moments
- **Empty states**: Subtle floating animations on illustrations
- **Completed actions**: Confetti, check mark flourish, success celebrations
- **Easter eggs**: Hidden interactions for discovery
- **Contextual animation**: Weather effects, time-of-day themes, seasonal touches

## Technical Implementation

Use appropriate techniques for each animation:

### Timing & Easing

**Durations by purpose:**
- **100-150ms**: Instant feedback (button press, toggle)
- **200-300ms**: State changes (hover, menu open)
- **300-500ms**: Layout changes (accordion, modal)
- **500-800ms**: Entrance animations (page load)

**Easing curves (use these, not CSS defaults):**
```css
/* Recommended - natural deceleration */
--ease-out-quart: cubic-bezier(0.25, 1, 0.5, 1);    /* Smooth, refined */
--ease-out-quint: cubic-bezier(0.22, 1, 0.36, 1);   /* Slightly snappier */
--ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);     /* Confident, decisive */

/* AVOID - feel dated and tacky */
/* bounce: cubic-bezier(0.34, 1.56, 0.64, 1); */
/* elastic: cubic-bezier(0.68, -0.6, 0.32, 1.6); */
```

**Exit animations are faster than entrances.** Use ~75% of enter duration.

### CSS Animations
```css
/* Prefer for simple, declarative animations */
- transitions for state changes
- @keyframes for complex sequences
- transform + opacity only (GPU-accelerated)
```

### JavaScript Animation
```javascript
/* Use for complex, interactive animations */
- Web Animations API for programmatic control
- Framer Motion for React
- GSAP for complex sequences
```

### Performance
- **GPU acceleration**: Use `transform` and `opacity`, avoid layout properties
- **will-change**: Add sparingly for known expensive animations
- **Reduce paint**: Minimize repaints, use `contain` where appropriate
- **Monitor FPS**: Ensure 60fps on target devices

### Accessibility
```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

**NEVER**:
- Use bounce or elastic easing curves—they feel dated and draw attention to the animation itself
- Animate layout properties (width, height, top, left)—use transform instead
- Use durations over 500ms for feedback—it feels laggy
- Animate without purpose—every animation needs a reason
- Ignore `prefers-reduced-motion`—this is an accessibility violation
- Animate everything—animation fatigue makes interfaces feel exhausting
- Block interaction during animations unless intentional

## Verify Quality

Test animations thoroughly:

- **Smooth at 60fps**: No jank on target devices
- **Feels natural**: Easing curves feel organic, not robotic
- **Appropriate timing**: Not too fast (jarring) or too slow (laggy)
- **Reduced motion works**: Animations disabled or simplified appropriately
- **Doesn't block**: Users can interact during/after animations
- **Adds value**: Makes interface clearer or more delightful

Remember: Motion should enhance understanding and provide feedback, not just add decoration. Animate with purpose, respect performance constraints, and always consider accessibility. Great animation is invisible - it just makes everything feel right.

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
- **tone down overly bold or aggressive designs** — check `quieter` if appropriate.
- **amplify bland/safe designs** — check `bolder` if appropriate.
- **go all-out — shaders, springs, scroll-driven reveals** — check `overdrive` if appropriate.
- **responsive design across viewports** — check `adapt` if appropriate.
- **typography — fonts, hierarchy, size, weight** — check `typeset` if appropriate.
- **spacing, grids, visual rhythm** — check `layout` if appropriate.
- **color systems** — check `colorize` if appropriate.
- **performance — load time, bundle, jank** — check `optimize` if appropriate.

<!-- cross-ref:end -->

