# Task Breakdown Patterns

Guidance for breaking down projects into effective Ralph tasks.

## The 5-30 Minute Rule

Each task should take Ralph 5-30 minutes to complete:

| Too Broad | Just Right | Too Narrow |
|-----------|------------|------------|
| "Build authentication" | "Implement login endpoint" | "Create auth.ts file" |
| "Create frontend" | "Build TodoList component" | "Add import statement" |
| "Set up database" | "Define User model in Prisma" | "Add id field to User" |

## Task Granularity Examples

### Feature Implementation

**Too broad:**
```markdown
- [ ] Implement user authentication
```

**Properly broken down:**
```markdown
- [ ] Create User model with email, passwordHash, createdAt
- [ ] Implement POST /auth/register endpoint
- [ ] Implement POST /auth/login endpoint
- [ ] Create JWT token generation utility
- [ ] Add auth middleware for protected routes
- [ ] Write tests for auth endpoints
```

### API Endpoint

**Too broad:**
```markdown
- [ ] Create CRUD API for tasks
```

**Properly broken down:**
```markdown
- [ ] Define Task model in Prisma schema
- [ ] Run migration for Task table
- [ ] Implement GET /tasks (list with pagination)
- [ ] Implement POST /tasks (create)
- [ ] Implement GET /tasks/:id (single)
- [ ] Implement PUT /tasks/:id (update)
- [ ] Implement DELETE /tasks/:id
- [ ] Add Zod validation for task input
```

### UI Component

**Too broad:**
```markdown
- [ ] Build dashboard page
```

**Properly broken down:**
```markdown
- [ ] Create DashboardLayout component
- [ ] Build StatCard component for metrics
- [ ] Implement RecentActivity list
- [ ] Create QuickActions panel
- [ ] Add loading skeletons
- [ ] Connect to API data
```

## Phase Structure Patterns

### Standard Web App Phases

```markdown
## Phase 1: Foundation (Setup)
- Project initialization
- Build tools configuration
- Database connection
- Basic project structure

## Phase 2: Data Layer (Models)
- Database schema
- Migrations
- Seed data

## Phase 3: Backend (API)
- Authentication
- Core endpoints
- Validation
- Error handling

## Phase 4: Frontend (UI)
- Routing
- Layout components
- Feature pages
- API integration

## Phase 5: Testing
- Unit tests
- Integration tests
- E2E tests

## Phase 6: Polish
- Error messages
- Loading states
- Documentation
```

### Feature-Focused Phases

For projects organized by feature rather than layer:

```markdown
## Phase 1: Foundation
- Project setup
- Shared infrastructure

## Phase 2: Feature - User Management
- User model and API
- Registration/login UI
- Profile page

## Phase 3: Feature - Projects
- Project model and API
- Project list/detail UI
- Project settings

## Phase 4: Feature - Tasks
- Task model and API
- Task board UI
- Drag-drop reordering

## Phase 5: Integration & Testing
- Cross-feature workflows
- Full test coverage
```

## Task Dependencies

### Explicit Dependencies

Mark blocking dependencies in task descriptions:

```markdown
- [ ] Create User model in Prisma
- [ ] Implement login endpoint (requires: User model)
- [ ] Build LoginForm component (requires: login endpoint)
```

### Phase Ordering

Tasks within a phase can be done in any order. Tasks in later phases depend on earlier phases completing.

```markdown
## Phase 1: Foundation
- [ ] Initialize project          # Independent
- [ ] Set up database connection  # Independent
- [ ] Configure TypeScript        # Independent

## Phase 2: Models (requires Phase 1)
- [ ] Create User model
- [ ] Create Task model
```

## Task Acceptance Criteria

For ambiguous tasks, add acceptance criteria:

```markdown
- [ ] Implement pagination for task list
  - Default page size: 20
  - Support `?page=N&limit=M` query params
  - Return total count in response
  - Handle edge cases (empty, last page)
```

## Complex Project Patterns

### Checkpoint Pattern

For projects with 50+ tasks, add explicit checkpoints:

```markdown
## Phase 1: Foundation
[tasks...]

### CHECKPOINT: Foundation Complete
- [ ] Verify project runs without errors
- [ ] Verify database migrations work
- [ ] Verify tests pass

## Phase 2: Core Features
[tasks...]

### CHECKPOINT: Core Features Complete
- [ ] Demo all CRUD operations
- [ ] Verify 80%+ test coverage
```

### Rollback Criteria

For high-risk tasks, document rollback:

```markdown
- [ ] Migrate database schema to v2
  - Backup: Run `pg_dump` before migration
  - Rollback: Run `prisma migrate reset` if failed
  - Verify: All existing data accessible
```

## Common Task Patterns

### Setup Tasks
```markdown
- [ ] Initialize [framework] project with TypeScript
- [ ] Configure ESLint with [ruleset]
- [ ] Set up Prettier with project config
- [ ] Configure [testing framework]
- [ ] Create .env.example with required variables
```

### Model Tasks
```markdown
- [ ] Define [Model] schema in Prisma
- [ ] Add indexes for [fields]
- [ ] Create migration for [Model]
- [ ] Generate Prisma client
- [ ] Add seed data for [Model]
```

### API Tasks
```markdown
- [ ] Implement GET /[resources] with pagination
- [ ] Implement POST /[resources] with validation
- [ ] Implement GET /[resources]/:id
- [ ] Implement PUT /[resources]/:id
- [ ] Implement DELETE /[resources]/:id
- [ ] Add authentication to [resource] routes
```

### Component Tasks
```markdown
- [ ] Create [Component] with props interface
- [ ] Add loading state to [Component]
- [ ] Add error state to [Component]
- [ ] Add empty state to [Component]
- [ ] Write tests for [Component]
```

### Testing Tasks
```markdown
- [ ] Unit tests for [module] (80%+ coverage)
- [ ] Integration tests for [feature] API
- [ ] E2E test for [user flow]
- [ ] Test error handling in [component]
```

## Anti-Patterns to Avoid

### Vague Tasks
```markdown
# Bad
- [ ] Make it work
- [ ] Fix bugs
- [ ] Improve performance

# Good
- [ ] Fix null pointer error in UserService.getById
- [ ] Add database index for User.email lookups
- [ ] Reduce bundle size by code-splitting routes
```

### Compound Tasks
```markdown
# Bad
- [ ] Set up project and create models and build API

# Good
- [ ] Set up project with TypeScript
- [ ] Create User model
- [ ] Create Task model
- [ ] Build User API endpoints
- [ ] Build Task API endpoints
```

### Missing Context
```markdown
# Bad
- [ ] Add validation

# Good
- [ ] Add Zod validation for POST /tasks request body
  - title: required, 1-200 chars
  - status: optional, enum ['todo', 'done']
```
