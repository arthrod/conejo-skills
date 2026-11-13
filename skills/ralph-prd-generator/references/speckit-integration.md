# Spec-Kit Integration Guide

Integrate GitHub's Spec-Kit with Ralph for a powerful specification-to-implementation workflow.

## What is Spec-Kit?

Spec-Kit is GitHub's toolkit for Spec-Driven Development. It provides a structured workflow:

1. `/speckit.constitution` - Define project principles
2. `/speckit.specify` - Write functional specifications
3. `/speckit.plan` - Create technical implementation plan
4. `/speckit.tasks` - Generate task breakdown
5. `/speckit.implement` - Execute implementation

## Why Combine Spec-Kit + Ralph?

| Spec-Kit Strengths | Ralph Strengths |
|-------------------|-----------------|
| Structured planning | Autonomous execution |
| AI-assisted specs | Loop until complete |
| Tech stack research | Circuit breaker safety |
| Task breakdown | Session continuity |

**Together**: Use Spec-Kit for thorough planning, Ralph for tireless implementation.

## File Mapping

| Spec-Kit File | Location | Ralph File |
|--------------|----------|------------|
| `constitution.md` | `.specify/memory/` | `PROMPT.md` (quality standards) |
| `spec.md` | `.specify/specs/<feature>/` | `specs/requirements.md` |
| `plan.md` | `.specify/specs/<feature>/` | `PROMPT.md` (tech stack) |
| `tasks.md` | `.specify/specs/<feature>/` | `@fix_plan.md` |
| `data-model.md` | `.specify/specs/<feature>/` | `specs/data-models.md` |
| `api-spec.json` | `.specify/specs/<feature>/contracts/` | `specs/api-endpoints.md` |
| `research.md` | `.specify/specs/<feature>/` | `specs/research.md` |

## Workflow Options

### Option 1: Spec-Kit First, Then Ralph (Recommended)

Best for complex projects needing thorough planning.

```bash
# 1. Initialize Spec-Kit project
specify init my-app --ai claude

# 2. Run Spec-Kit planning workflow
cd my-app
claude  # Start Claude Code

/speckit.constitution Focus on code quality, testing, accessibility
/speckit.specify Build a task management app with projects, tasks, and team collaboration
/speckit.plan Use React 18, TypeScript, Express, PostgreSQL, Prisma
/speckit.tasks

# 3. Convert to Ralph format
python scripts/speckit_to_ralph.py . ./ralph-project

# 4. Switch to Ralph for implementation
cd ralph-project
ralph --monitor
```

### Option 2: Manual Integration

For more control over the conversion.

**Step 1: Extract from Spec-Kit**

After running Spec-Kit commands, you'll have:
```
.specify/
├── memory/
│   └── constitution.md      # Project principles
└── specs/
    └── 001-my-feature/
        ├── spec.md          # Requirements
        ├── plan.md          # Technical plan
        ├── tasks.md         # Task breakdown
        ├── data-model.md    # Data schemas
        └── contracts/
            └── api-spec.json
```

**Step 2: Create Ralph PROMPT.md**

```markdown
# [Feature Name] Development Instructions

You are Ralph, an autonomous AI development agent.

## Your Mission

[Copy from spec.md overview section]

## Technical Requirements

[Copy from plan.md technology stack section]

## Quality Standards

[Copy from constitution.md]

## Project Structure

[Copy from plan.md project structure section]

## Process

1. Read @fix_plan.md and select the highest priority incomplete task
2. Implement the task following specs in specs/
3. Write tests for the implementation
4. Update @fix_plan.md to mark the task complete
5. Commit with a meaningful message

## RALPH_STATUS Format

## RALPH_STATUS
- STATUS: [IN_PROGRESS | COMPLETE | BLOCKED]
- EXIT_SIGNAL: [true | false]
- PROGRESS: [What was accomplished]
- NEXT_STEPS: [What remains]

Set EXIT_SIGNAL to true ONLY when ALL tasks complete and tests pass.
```

**Step 3: Convert tasks.md to @fix_plan.md**

Spec-Kit tasks.md structure:
```markdown
## User Story 1: Create Projects
- [P] Create project model
- [P] Implement project service
- [ ] Add project API endpoints
- [ ] Write project tests
```

Ralph @fix_plan.md structure:
```markdown
# Fix Plan

## Phase 1: User Story - Create Projects
- [ ] Create project model
- [ ] Implement project service
- [ ] Add project API endpoints
- [ ] Write project tests

## Completed
```

**Step 4: Copy spec files**

```bash
mkdir -p specs
cp .specify/specs/001-*/spec.md specs/requirements.md
cp .specify/specs/001-*/data-model.md specs/data-models.md
# Convert api-spec.json to markdown manually or use script
```

### Option 3: Hybrid Workflow

Use Spec-Kit interactively, Ralph for automation.

```
┌─────────────────────────────────────────────────────────────┐
│                    HYBRID WORKFLOW                          │
└─────────────────────────────────────────────────────────────┘

   SPEC-KIT (Interactive)              RALPH (Autonomous)
   ─────────────────────               ───────────────────
   
   /speckit.constitution  ───────►    
   /speckit.specify       ───────►    specs/requirements.md
   /speckit.clarify       ───────►    
   /speckit.plan          ───────►    PROMPT.md (tech stack)
   /speckit.tasks         ───────►    @fix_plan.md
                                              │
                                              ▼
                                      ralph --monitor
                                      (autonomous loop)
                                              │
                                              ▼
                                      Implementation complete!
```

## Conversion Script Usage

The skill includes `speckit_to_ralph.py` for automatic conversion:

```bash
# Convert Spec-Kit project to Ralph format
python scripts/speckit_to_ralph.py ./my-speckit-project ./ralph-output

# Convert current directory
python scripts/speckit_to_ralph.py . ./ralph-output
```

**What the script does:**

1. Finds Spec-Kit files in `.specify/` directory
2. Extracts tech stack from `plan.md`
3. Extracts quality standards from `constitution.md`
4. Converts `tasks.md` to `@fix_plan.md` format
5. Copies spec files to `specs/` directory
6. Generates `PROMPT.md` with RALPH_STATUS block
7. Creates stub `@AGENT.md`

## Best Practices

### 1. Let Spec-Kit Do the Planning

Spec-Kit excels at:
- Clarifying requirements (`/speckit.clarify`)
- Research (`research.md`)
- Tech stack decisions
- Task decomposition

Don't skip these steps - they reduce rework.

### 2. Review Before Converting

Before running the conversion:
- Verify all `/speckit.clarify` questions answered
- Check `research.md` for any open questions
- Ensure `tasks.md` has appropriate granularity

### 3. Customize PROMPT.md After Conversion

The generated PROMPT.md is a starting point. Add:
- Project-specific constraints
- Additional quality criteria
- Edge cases to handle
- EXIT_SIGNAL conditions specific to your project

### 4. Validate Ralph Project Structure

After conversion:
```bash
python scripts/validate_ralph_project.py ./ralph-output
```

### 5. Use Ralph's Safety Features

For overnight/unattended runs:
```bash
ralph --monitor --timeout 60 --calls 200
```

Circuit breaker will halt if:
- Same error 5+ times
- No file changes 3+ loops
- Output declining 70%+

## Example: Full Workflow

```bash
# === PHASE 1: SPEC-KIT PLANNING ===

# Initialize
specify init photo-organizer --ai claude
cd photo-organizer

# Start Claude Code
claude

# Define principles
/speckit.constitution Focus on performance, offline-first, intuitive UX

# Write spec
/speckit.specify Build a photo organization app that groups photos by date 
into albums. Support drag-drop reorganization. Store metadata locally.

# Clarify ambiguities
/speckit.clarify

# Create technical plan
/speckit.plan Use Vite, vanilla JS/HTML/CSS, SQLite for local storage

# Generate tasks
/speckit.tasks

# Exit Claude Code
# Ctrl+C


# === PHASE 2: CONVERT TO RALPH ===

python ~/.claude/skills/ralph-prd-generator/scripts/speckit_to_ralph.py . ./ralph-project


# === PHASE 3: RALPH IMPLEMENTATION ===

cd ralph-project

# Review generated files
cat PROMPT.md
cat @fix_plan.md

# Customize if needed
nano PROMPT.md

# Start autonomous development
ralph --monitor

# Let Ralph build while you sleep... 💤
```

## Troubleshooting

### Conversion fails to find files

Ensure Spec-Kit workflow was completed:
```bash
ls .specify/specs/*/spec.md
ls .specify/specs/*/plan.md
ls .specify/specs/*/tasks.md
```

### Tasks not converting properly

Manual conversion fallback:
1. Copy `tasks.md` content
2. Replace task headers with `## Phase N: [Name]`
3. Ensure all tasks have `- [ ]` markers
4. Add `## Completed` section at end

### PROMPT.md missing tech stack

If `plan.md` doesn't have clear technology section:
1. Check `research.md` for tech decisions
2. Add manually to PROMPT.md
3. Be explicit about versions

### Ralph exits too early

Add explicit exit conditions to PROMPT.md:
```markdown
## Exit Conditions

Set EXIT_SIGNAL to true ONLY when:
- All @fix_plan.md tasks marked [x]
- All tests passing (npm test exits 0)
- Build succeeds (npm run build exits 0)
- No TypeScript errors
```
