# PRD Templates by Project Type

Complete templates for generating Ralph-compatible project structures.

## Web Application (React + Express)

### PROMPT.md Template

```markdown
# [Project Name] Development Instructions

You are Ralph, an autonomous AI development agent building [brief description].

## Your Mission

[2-3 sentences describing the goal and why it matters to users]

## Technical Requirements

| Component | Technology |
|-----------|------------|
| Frontend | React 18 + TypeScript |
| Backend | Express + TypeScript |
| Database | PostgreSQL + Prisma |
| Testing | Vitest (unit), Playwright (e2e) |
| Styling | Tailwind CSS |

## Project Structure

```
project/
├── apps/
│   ├── web/              # React frontend
│   │   ├── src/
│   │   │   ├── components/
│   │   │   ├── pages/
│   │   │   ├── hooks/
│   │   │   └── lib/
│   │   └── package.json
│   └── api/              # Express backend
│       ├── src/
│       │   ├── routes/
│       │   ├── services/
│       │   ├── middleware/
│       │   └── db/
│       └── package.json
├── packages/
│   └── shared/           # Shared types/utils
├── prisma/
│   └── schema.prisma
└── package.json
```

## Quality Standards

1. TypeScript strict mode enabled
2. All functions have explicit return types
3. Components use proper prop typing
4. API endpoints have request/response validation
5. 80%+ test coverage for business logic

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

### @fix_plan.md Template

```markdown
# Fix Plan - [Project Name]

## Phase 1: Foundation
- [ ] Initialize monorepo with pnpm workspaces
- [ ] Set up Express backend with TypeScript
- [ ] Set up React frontend with Vite
- [ ] Configure Prisma with PostgreSQL
- [ ] Set up shared types package
- [ ] Configure ESLint and Prettier

## Phase 2: Database & Models
- [ ] Define database schema in Prisma
- [ ] Generate Prisma client
- [ ] Create seed script with sample data

## Phase 3: Backend API
- [ ] Implement authentication middleware
- [ ] Create [Resource 1] CRUD endpoints
- [ ] Create [Resource 2] CRUD endpoints
- [ ] Add request validation with Zod
- [ ] Add error handling middleware

## Phase 4: Frontend Core
- [ ] Set up routing with React Router
- [ ] Create layout components (Header, Sidebar)
- [ ] Implement authentication flow
- [ ] Create API client with fetch wrapper

## Phase 5: Frontend Features
- [ ] Build [Feature 1] page and components
- [ ] Build [Feature 2] page and components
- [ ] Add loading states and error handling
- [ ] Implement responsive design

## Phase 6: Testing
- [ ] Unit tests for backend services
- [ ] Unit tests for React components
- [ ] Integration tests for API endpoints
- [ ] E2E tests for critical user flows

## Phase 7: Polish
- [ ] Add form validation feedback
- [ ] Improve error messages
- [ ] Optimize bundle size
- [ ] Write README with setup instructions

## Completed
(Tasks moved here when done)
```

---

## CLI Tool (Node.js)

### PROMPT.md Template

```markdown
# [CLI Name] Development Instructions

You are Ralph, an autonomous AI development agent building a CLI tool that [description].

## Your Mission

Build a command-line tool that [primary purpose]. Users should be able to [key actions].

## Technical Requirements

| Component | Technology |
|-----------|------------|
| Runtime | Node.js 18+ |
| Language | TypeScript |
| CLI Framework | Commander.js |
| Config | cosmiconfig |
| Testing | Vitest |

## Project Structure

```
cli-tool/
├── src/
│   ├── index.ts          # Entry point
│   ├── cli.ts            # Command definitions
│   ├── commands/         # Command handlers
│   │   ├── init.ts
│   │   └── run.ts
│   ├── lib/              # Core logic
│   └── utils/            # Helpers
├── bin/
│   └── cli.js            # Shebang entry
├── tests/
├── tsconfig.json
└── package.json
```

## Quality Standards

1. Commands have --help with usage examples
2. Exit codes are meaningful (0 success, 1 error)
3. Errors show helpful messages, not stack traces
4. Interactive prompts have non-interactive fallbacks
5. Configuration is validated on load

## Process

1. Read @fix_plan.md and select the highest priority incomplete task
2. Implement the task
3. Test manually: `npm link && cli-name --help`
4. Write automated tests
5. Update @fix_plan.md to mark task complete
6. Commit with meaningful message

## RALPH_STATUS Format

## RALPH_STATUS
- STATUS: [IN_PROGRESS | COMPLETE | BLOCKED]
- EXIT_SIGNAL: [true | false]
- PROGRESS: [What was accomplished]
- NEXT_STEPS: [What remains]

Set EXIT_SIGNAL to true ONLY when ALL tasks complete and tests pass.
```

### @fix_plan.md Template

```markdown
# Fix Plan - [CLI Name]

## Phase 1: Foundation
- [ ] Initialize TypeScript project
- [ ] Set up Commander.js CLI structure
- [ ] Configure build with esbuild/tsup
- [ ] Create bin entry point with shebang
- [ ] Set up Vitest for testing

## Phase 2: Core Commands
- [ ] Implement `init` command
- [ ] Implement `run` command
- [ ] Implement `config` command
- [ ] Add global options (--verbose, --quiet)

## Phase 3: Configuration
- [ ] Set up cosmiconfig for config files
- [ ] Define config schema with validation
- [ ] Support .rc, .json, and package.json config

## Phase 4: Core Logic
- [ ] Implement [core feature 1]
- [ ] Implement [core feature 2]
- [ ] Add progress indicators (ora/cli-progress)

## Phase 5: Testing & Polish
- [ ] Unit tests for each command
- [ ] Integration tests for workflows
- [ ] Add --version flag
- [ ] Write comprehensive --help text
- [ ] Create README with examples

## Completed
```

---

## REST API (Express/FastAPI)

### PROMPT.md Template

```markdown
# [API Name] Development Instructions

You are Ralph, an autonomous AI development agent building a REST API for [purpose].

## Your Mission

Build a RESTful API that [description]. The API will be consumed by [clients].

## Technical Requirements

| Component | Technology |
|-----------|------------|
| Framework | Express + TypeScript |
| Database | PostgreSQL + Prisma |
| Auth | JWT with refresh tokens |
| Validation | Zod |
| Docs | OpenAPI/Swagger |
| Testing | Vitest + Supertest |

## Project Structure

```
api/
├── src/
│   ├── index.ts          # Entry point
│   ├── app.ts            # Express app config
│   ├── routes/           # Route definitions
│   │   ├── index.ts
│   │   └── [resource].ts
│   ├── controllers/      # Request handlers
│   ├── services/         # Business logic
│   ├── middleware/       # Auth, validation, errors
│   ├── db/               # Prisma client
│   └── types/            # TypeScript types
├── prisma/
│   └── schema.prisma
├── tests/
└── package.json
```

## API Design Standards

1. RESTful resource naming (plural nouns)
2. Proper HTTP methods (GET, POST, PUT, PATCH, DELETE)
3. Consistent response format: `{ data, error, meta }`
4. Pagination with limit/offset
5. Filter and sort query parameters

## Process

1. Read @fix_plan.md and select the highest priority incomplete task
2. Implement the task following specs in specs/
3. Test with curl or API client
4. Write automated tests
5. Update @fix_plan.md to mark task complete
6. Commit with meaningful message

## RALPH_STATUS Format

## RALPH_STATUS
- STATUS: [IN_PROGRESS | COMPLETE | BLOCKED]
- EXIT_SIGNAL: [true | false]
- PROGRESS: [What was accomplished]
- NEXT_STEPS: [What remains]

Set EXIT_SIGNAL to true ONLY when ALL tasks complete and tests pass.
```

---

## Specification File Templates

### specs/data-models.md

```markdown
# Data Models

## User

```typescript
interface User {
  id: string;           // UUID
  email: string;        // unique, validated
  name: string;
  passwordHash: string; // bcrypt hashed
  createdAt: Date;
  updatedAt: Date;
}
```

### Validation Rules
- email: valid email format, max 255 chars
- name: 1-100 chars, no special chars except space/hyphen
- password: min 8 chars, must have uppercase, lowercase, number

### Relationships
- User has many [Resources]

---

## [Resource]

```typescript
interface Resource {
  id: string;
  userId: string;       // FK to User
  title: string;
  status: 'draft' | 'active' | 'archived';
  createdAt: Date;
  updatedAt: Date;
}
```

### Validation Rules
- title: 1-200 chars
- status: enum value

### Indexes
- userId (for queries by owner)
- status (for filtering)
- createdAt (for sorting)
```

### specs/api-endpoints.md

```markdown
# API Endpoints

Base URL: `/api/v1`

## Authentication

### POST /auth/register
Create new user account.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123",
  "name": "John Doe"
}
```

**Response (201):**
```json
{
  "data": {
    "user": { "id": "...", "email": "...", "name": "..." },
    "token": "jwt..."
  }
}
```

**Errors:**
- 400: Validation failed
- 409: Email already exists

---

### POST /auth/login
Authenticate user.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123"
}
```

**Response (200):**
```json
{
  "data": {
    "user": { "id": "...", "email": "...", "name": "..." },
    "token": "jwt...",
    "refreshToken": "..."
  }
}
```

---

## Resources

### GET /resources
List resources with pagination.

**Query Parameters:**
- `limit` (default: 20, max: 100)
- `offset` (default: 0)
- `status` (filter by status)
- `sort` (field to sort by)
- `order` (asc/desc)

**Response (200):**
```json
{
  "data": [...],
  "meta": {
    "total": 100,
    "limit": 20,
    "offset": 0
  }
}
```

### POST /resources
Create new resource.

### GET /resources/:id
Get single resource.

### PUT /resources/:id
Update resource (full replacement).

### PATCH /resources/:id
Partial update resource.

### DELETE /resources/:id
Delete resource.
```

### specs/ui-components.md

```markdown
# UI Components

## Layout Components

### AppLayout
Main application layout with header, sidebar, and content area.

**Props:**
```typescript
interface AppLayoutProps {
  children: ReactNode;
  showSidebar?: boolean;
}
```

**Behavior:**
- Header fixed at top
- Sidebar collapsible on mobile
- Content area scrollable

---

### Header
Top navigation bar.

**Contains:**
- Logo (links to home)
- Navigation links
- User menu (avatar, dropdown)
- Mobile menu toggle

---

## Feature Components

### ResourceList
Displays paginated list of resources.

**Props:**
```typescript
interface ResourceListProps {
  resources: Resource[];
  isLoading: boolean;
  onEdit: (id: string) => void;
  onDelete: (id: string) => void;
}
```

**States:**
- Loading: show skeleton
- Empty: show empty state with CTA
- Error: show error message with retry
- Success: show resource cards

---

### ResourceForm
Create/edit resource form.

**Props:**
```typescript
interface ResourceFormProps {
  resource?: Resource;  // undefined for create
  onSubmit: (data: ResourceInput) => Promise<void>;
  onCancel: () => void;
}
```

**Validation:**
- Client-side with react-hook-form + zod
- Show inline errors
- Disable submit while invalid
```
