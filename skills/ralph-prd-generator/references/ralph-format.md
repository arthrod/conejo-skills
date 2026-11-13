# Ralph File Format Specification

Detailed specifications for Ralph-compatible project files.

## Required Files

| File | Purpose | Required |
|------|---------|----------|
| `PROMPT.md` | Main development instructions | **Yes** |
| `@fix_plan.md` | Prioritized task checklist | **Yes** |
| `specs/*.md` | Technical specifications | Recommended |
| `@AGENT.md` | Build/run instructions | Optional |

## PROMPT.md Specification

### Required Sections

#### 1. Title and Role
```markdown
# [Project Name] Development Instructions

You are Ralph, an autonomous AI development agent building [brief description].
```

#### 2. Mission Statement
```markdown
## Your Mission

[2-3 sentences describing:
- What the project does
- Who it's for
- Why it matters]
```

#### 3. Technical Requirements
```markdown
## Technical Requirements

[Table or list of technologies with versions]

| Component | Technology |
|-----------|------------|
| Language  | TypeScript 5.x |
| Framework | React 18 |
| Database  | PostgreSQL 15 |
```

#### 4. Project Structure
```markdown
## Project Structure

```
src/
├── components/
├── pages/
└── lib/
```
```

#### 5. Process Instructions
```markdown
## Process

1. Read @fix_plan.md and select the highest priority incomplete task
2. Implement the task following specs in specs/
3. Write tests for the implementation
4. Update @fix_plan.md to mark task complete
5. Commit with meaningful message
```

#### 6. RALPH_STATUS Block (Critical)
```markdown
## RALPH_STATUS Format

At the end of each response, include:

## RALPH_STATUS
- STATUS: [IN_PROGRESS | COMPLETE | BLOCKED]
- EXIT_SIGNAL: [true | false]
- PROGRESS: [What was accomplished]
- NEXT_STEPS: [What remains]

Set EXIT_SIGNAL to true ONLY when ALL tasks complete and tests pass.
```

### Optional Sections

#### Quality Standards
```markdown
## Quality Standards

1. [Standard 1]
2. [Standard 2]
```

#### Constraints
```markdown
## Constraints

- Do not use [technology/pattern]
- Must be compatible with [requirement]
```

#### Exit Conditions
```markdown
## Exit Conditions

Set EXIT_SIGNAL to true ONLY when:
- All @fix_plan.md tasks marked [x]
- All tests passing
- Build succeeds
- No linting errors
```

---

## @fix_plan.md Specification

### Format

```markdown
# Fix Plan - [Project Name]

## Phase 1: [Phase Name]
- [ ] Task 1
- [ ] Task 2
  - [ ] Subtask 2.1
  - [ ] Subtask 2.2

## Phase 2: [Phase Name]
- [ ] Task 3

## Completed
- [x] Completed task (moved here when done)
```

### Task Markers

| Marker | Meaning |
|--------|---------|
| `- [ ]` | Incomplete task |
| `- [x]` | Completed task |
| `- [~]` | In progress (optional) |
| `- [!]` | Blocked (optional) |

### Phase Naming Conventions

Standard phases:
- `Phase 1: Foundation` - Project setup, configuration
- `Phase 2: Data Layer` - Models, database, migrations
- `Phase 3: Core Features` - Main functionality
- `Phase 4: Integration` - Connecting components
- `Phase 5: Testing` - Test coverage
- `Phase 6: Polish` - UX improvements, docs

### Task Completion Rules

1. Ralph marks tasks complete by changing `[ ]` to `[x]`
2. Completed tasks may be moved to `## Completed` section
3. New tasks discovered during implementation are added to appropriate phase
4. Subtasks indent with 2 spaces under parent task

---

## specs/ Directory

### Common Specification Files

| File | When to Include |
|------|-----------------|
| `data-models.md` | Apps with database/persistence |
| `api-endpoints.md` | REST/GraphQL APIs |
| `ui-components.md` | Frontend applications |
| `architecture.md` | Complex multi-service systems |
| `requirements.md` | Detailed functional requirements |

### specs/data-models.md Format

```markdown
# Data Models

## [ModelName]

```typescript
interface ModelName {
  id: string;
  field1: string;
  field2: number;
  createdAt: Date;
}
```

### Validation Rules
- field1: [constraints]
- field2: [constraints]

### Relationships
- ModelName has many [OtherModel]
- ModelName belongs to [OtherModel]

### Indexes
- field1 (for [query type])
```

### specs/api-endpoints.md Format

```markdown
# API Endpoints

Base URL: `/api/v1`

## [Resource]

### [METHOD] /[path]

[Description]

**Request:**
```json
{ }
```

**Response ([status]):**
```json
{ }
```

**Errors:**
- [status]: [description]
```

### specs/ui-components.md Format

```markdown
# UI Components

## [ComponentName]

[Description and purpose]

**Props:**
```typescript
interface ComponentProps {
  prop1: string;
  prop2?: number;
}
```

**States:**
- Loading: [behavior]
- Error: [behavior]
- Empty: [behavior]
- Success: [behavior]

**Events:**
- onClick: [handler]
- onSubmit: [handler]
```

---

## @AGENT.md Specification

Build and run instructions for the project.

### Format

```markdown
# Build & Run Instructions

## Prerequisites
- [Requirement 1]
- [Requirement 2]

## Setup
```bash
[setup commands]
```

## Development
```bash
[dev server command]
```

## Testing
```bash
[test command]
```

## Build
```bash
[build command]
```

## Environment Variables
| Variable | Description | Required |
|----------|-------------|----------|
| DATABASE_URL | PostgreSQL connection | Yes |
| JWT_SECRET | Token signing key | Yes |
```

---

## Runtime Files

Files created by Ralph during execution:

| File | Purpose |
|------|---------|
| `@progress.md` | Session progress log |
| `@errors.md` | Error log for debugging |
| `@decisions.md` | Architecture decisions made |

These files are created automatically and help with debugging and session continuity.

---

## Best Practices

### PROMPT.md
- Keep under 500 lines
- Be specific about tech stack versions
- Include explicit exit conditions
- Reference specs/ files for details

### @fix_plan.md
- Tasks should take 5-30 minutes each
- Group related tasks in phases
- Include testing in a dedicated phase
- Keep Completed section for visibility

### specs/
- Use TypeScript interfaces for data models
- Include validation rules
- Show request/response examples for APIs
- Document component states and behaviors

### @AGENT.md
- Test all commands before including
- Include environment variable documentation
- Provide troubleshooting tips
