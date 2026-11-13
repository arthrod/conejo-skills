---
name: ralph-prd-generator
description: Generates Product Requirements Documents (PRDs) and specifications for Ralph for Claude Code autonomous development. Use when users want to create a PRD, write specifications, plan a new project for Ralph, convert ideas into Ralph-compatible format (PROMPT.md, @fix_plan.md, specs/), or prepare requirements for autonomous AI development loops.
---

# Ralph PRD Generator

Generate comprehensive PRDs and specifications optimized for Ralph for Claude Code autonomous development loops.

## About Ralph

Ralph is an autonomous AI development framework that runs Claude Code in a continuous loop until tasks are complete. It requires three key files:

| File | Purpose | Required |
|------|---------|----------|
| `PROMPT.md` | Main development instructions | Yes |
| `@fix_plan.md` | Prioritized task checklist | Yes |
| `specs/*.md` | Detailed specifications | Recommended |

## Quick Start

1. Gather requirements from user (or generate from idea)
2. Create `PROMPT.md` with development instructions
3. Create `@fix_plan.md` with phased task breakdown
4. Create `specs/` files for detailed technical specs

## PRD Generation Workflow

### Step 1: Requirements Gathering

If the user provides only an idea, ask clarifying questions:

**Essential questions (ask first):**
- What problem does this solve?
- Who is the target user?
- What are the must-have features (MVP)?

**Technical questions (ask if not specified):**
- Preferred technology stack?
- Any integrations needed?
- Deployment target?

**Scope questions (ask to clarify boundaries):**
- What's explicitly out of scope for v1?
- Any constraints (time, budget, technical)?

Limit to 3-5 questions per message to avoid overwhelming users.

### Step 2: Generate PROMPT.md

PROMPT.md is the primary instruction file Claude reads each loop. Structure:

```markdown
# [Project Name] Development Instructions

You are Ralph, an autonomous AI development agent building [brief description].

## Your Mission

[2-3 sentences describing the goal and why it matters]

## Technical Requirements

- **Language**: [e.g., TypeScript]
- **Framework**: [e.g., React 18]
- **Database**: [e.g., PostgreSQL with Prisma]
- **Testing**: [e.g., Vitest with 80%+ coverage]

## Project Structure

```
src/
├── [directory]/
│   └── [files]
└── ...
```

## Quality Standards

1. [Standard 1]
2. [Standard 2]
3. [Standard 3]

## Process

1. Read @fix_plan.md and select the highest priority incomplete task
2. Implement the task following specs in specs/
3. Write tests for the implementation
4. Update @fix_plan.md to mark task complete
5. Commit with meaningful message

## RALPH_STATUS Format

At the end of each response, include:

## RALPH_STATUS
- STATUS: [IN_PROGRESS | COMPLETE | BLOCKED]
- EXIT_SIGNAL: [true | false]
- PROGRESS: [What was accomplished]
- NEXT_STEPS: [What remains]

Set EXIT_SIGNAL to true ONLY when ALL tasks complete and tests pass.
```

**Critical elements:**
- Clear mission statement
- Explicit technical stack
- RALPH_STATUS block (required for exit detection)
- EXIT_SIGNAL conditions (prevents premature exit)

### Step 3: Generate @fix_plan.md

@fix_plan.md is the task checklist. Use phased structure:

```markdown
# Fix Plan - [Project Name]

## Phase 1: Foundation
- [ ] Initialize project with [framework]
- [ ] Set up directory structure
- [ ] Configure linting and formatting
- [ ] Set up testing framework

## Phase 2: Core Features
- [ ] Implement [Feature 1]
  - [ ] [Subtask 1.1]
  - [ ] [Subtask 1.2]
- [ ] Implement [Feature 2]

## Phase 3: Integration
- [ ] Connect [Component A] to [Component B]
- [ ] Add error handling

## Phase 4: Polish
- [ ] Add loading states
- [ ] Improve error messages
- [ ] Write documentation

## Phase 5: Testing
- [ ] Unit tests for [module]
- [ ] Integration tests
- [ ] E2E tests (if applicable)

## Completed
(Tasks moved here when done)
```

**Task granularity rules:**
- Each task should take 5-30 minutes
- Too broad: "Build authentication" → Split into registration, login, tokens
- Too narrow: "Create user.ts file" → Combine with related tasks
- Include acceptance criteria for ambiguous tasks

### Step 4: Generate Specifications

Create `specs/` files for detailed technical information. Common files:

| File | When to Create |
|------|----------------|
| `specs/data-models.md` | Apps with data persistence |
| `specs/api-endpoints.md` | REST/GraphQL APIs |
| `specs/ui-components.md` | Frontend applications |
| `specs/architecture.md` | Complex multi-component systems |

See [references/prd-templates.md](references/prd-templates.md) for detailed templates.

## Output Patterns

### For Web Applications

```
my-project/
├── PROMPT.md
├── @fix_plan.md
├── specs/
│   ├── data-models.md
│   ├── api-endpoints.md
│   └── ui-components.md
└── @AGENT.md (optional build instructions)
```

### For CLI Tools

```
my-cli/
├── PROMPT.md
├── @fix_plan.md
├── specs/
│   └── commands.md
└── @AGENT.md
```

### For APIs/Services

```
my-api/
├── PROMPT.md
├── @fix_plan.md
├── specs/
│   ├── data-models.md
│   ├── api-endpoints.md
│   └── authentication.md
└── @AGENT.md
```

## Validation

Before delivering, verify:

1. **PROMPT.md** includes:
   - [ ] Clear mission statement
   - [ ] Technical stack specified
   - [ ] RALPH_STATUS block with EXIT_SIGNAL
   - [ ] Process section referencing @fix_plan.md

2. **@fix_plan.md** includes:
   - [ ] Phased task structure
   - [ ] Tasks with appropriate granularity (5-30 min each)
   - [ ] Foundation phase first
   - [ ] Testing phase included

3. **specs/** files include:
   - [ ] Data models with TypeScript interfaces
   - [ ] Validation rules where applicable
   - [ ] Examples for clarity

Run `scripts/validate_ralph_project.py <path>` to check structure.

## Advanced Patterns

### For Complex Projects

When projects exceed ~50 tasks, consider:
- Breaking into multiple phases with explicit checkpoints
- Adding `specs/phases/phase-1.md`, `specs/phases/phase-2.md`
- Including rollback criteria

### For Overnight Runs

Add to PROMPT.md:
```markdown
## Overnight Run Guidelines

Since this is unattended:
1. Be conservative—choose simpler approaches when uncertain
2. Commit frequently after each working feature
3. Don't break main—ensure tests pass before commits
4. If blocked on external dependency, skip and move to next task
```

### For Team Projects

Add `@AGENT.md` with:
```markdown
# Build & Run Instructions

## Prerequisites
- Node.js 18+
- PostgreSQL 14+

## Setup
```bash
npm install
cp .env.example .env
npm run db:migrate
```

## Development
```bash
npm run dev
```

## Testing
```bash
npm test
```
```

## Spec-Kit Integration

If using GitHub's Spec-Kit for planning, convert to Ralph format:

```bash
# After running /speckit.specify, /speckit.plan, /speckit.tasks
python scripts/speckit_to_ralph.py ./speckit-project ./ralph-output
```

**Workflow**: Spec-Kit (planning) → Convert → Ralph (autonomous implementation)

See [references/speckit-integration.md](references/speckit-integration.md) for detailed integration guide.

## Reference Files

For detailed templates and examples:
- **PRD templates by project type**: See [references/prd-templates.md](references/prd-templates.md)
- **Task breakdown patterns**: See [references/task-breakdown.md](references/task-breakdown.md)
- **Ralph file format details**: See [references/ralph-format.md](references/ralph-format.md)
- **Spec-Kit integration**: See [references/speckit-integration.md](references/speckit-integration.md)
