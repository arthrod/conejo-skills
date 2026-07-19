# Authorization: macros, roles, RLS

Step 6 of the build order. This is the part that actually isolates tenants.

## Statement-based access control

A shared package (importable by both API and web) defines resources and actions
once:

```ts
import { createAccessControl } from "better-auth/plugins/access";

export const statements = {
  organization: ["update", "delete"],
  member: ["create", "update", "delete"],
  invitation: ["create", "cancel"],
  workspace: ["read", "create", "update", "delete"],
  template: ["use", "create", "update", "delete"],
  playbook: ["create", "update", "delete", "apply", "approve"],
  auditLog: ["read"],
  // ...one entry per domain resource
} as const;

export const ac = createAccessControl(statements);
```

Note the vocabulary: actions are not limited to CRUD. `use`, `apply`, `approve`
are real, distinct capabilities — an intern who may *use* a template must not be
able to *edit* it. If your action list is only `read`/`write`, you have not
modelled the domain yet.

Derive the permission input type so call sites cannot pass an empty object:

```ts
type PermissionMap = { [K in keyof typeof statements]: (typeof statements)[K][number][] };

type RequireAtLeastOne<T> = {
  [K in keyof T]-?: Required<Pick<T, K>> & Partial<Omit<T, K>>;
}[keyof T];

export type PermissionInput = RequireAtLeastOne<Partial<PermissionMap>>;
```

`permissions: {}` on a route would otherwise typecheck and authorize everyone.

## Roles

Five is a good starting shape. Build each by selecting a subset, and derive
adjacent roles from each other rather than retyping:

- `owner` — everything
- `admin` — owner minus `organization:delete`
- `member` — the default working role
- `intern` — workspace read, template/styleSet `use`, own time/expense, chat
- `external` — workspace read only (clients, opposing counsel, auditors)

Export a `roles` map keyed by role name. The runtime check is one line:

```ts
export const hasMemberPermission = (
  memberRole: AuthorizedMemberRole,
  permissions: PermissionInput,
): boolean => roles[memberRole.role].authorize(permissions).success;
```

Use the **local** role map, not a second Better Auth session read. One session
read per request.

## Reading the role off the context defensively

The role arrives on the Elysia context via a macro resolve, so its presence is
not guaranteed by the type system at every call site. Narrow with `Object.hasOwn`
and return `null` rather than trusting the shape:

```ts
const hasOwnMemberRole = (ctx: object): ctx is MemberRoleContext =>
  Object.hasOwn(ctx, "memberRole");

export const readAuthorizedMemberRole = (ctx: object): AuthorizedMemberRole | null => {
  if (!hasOwnMemberRole(ctx)) return null;
  const { memberRole } = ctx;
  if (typeof memberRole !== "object" || memberRole === null || !hasOwnRole(memberRole)) return null;
  const { role } = memberRole;
  if (typeof role !== "string" || !isMemberRole(role)) return null;
  return { role };
};
```

A missing role must read as *unauthorized*, never as *unrestricted*.

## The macro stack

Four macros, each layered on the previous.

### `sessionAuthMacro` — session only

For routes that need a user but no tenant (account settings, org creation).
500 on resolution error, 401 on no session or no user, returns `{ user: { id } }`
and enriches the observability context.

### `authMacro` — full resolution, memoized

```ts
const validateAuthResolutionCache = new WeakMap<Request, Promise<ValidateAuthResolution>>();

export const authMacro = new Elysia({ name: "authMacro" }).macro({
  validateAuth: {
    async resolve({ params, query, status, request, server }) {
      const initialWorkspaceId = readInitialWorkspaceId(params, query);
      const result = await memoizePerRequest(
        validateAuthResolutionCache,
        request,
        async () => await resolveValidateAuth(request, server, initialWorkspaceId),
      );
      if (!result.ok) return status(result.statusCode);
      return result.value;
    },
  },
});
```

The memoization is mandatory — see SKILL.md for why, and note that the cached
value is the **in-flight promise**, so concurrent resolves within one hook chain
still compute once.

`readInitialWorkspaceId` reads a workspace ID from params/query purely as a
*hint* to fold the workspace lookup into the membership query. It is not
authorized until the join returns a row. Naming matters here: call it
`initial`/`candidate`, never `workspaceId`, so nobody downstream mistakes it for
a validated value.

The resolution returns the whole authenticated request surface: user ID, active
organization ID, workspace accessors, **scoped and safe DB handles**, member
role, org AI config, and audit recorders. Handlers receive capabilities, not raw
IDs to filter by themselves.

Leave its return type inferred. Annotating collapses the scoped-DB generics.

### `permissionMacro` — role check before any work

```ts
export const permissionMacro = new Elysia({ name: "permissionMacro" })
  .use(authMacro)
  .macro("permissions", (permissions: PermissionInput) => ({
    validateAuth: true,
    body: t.Object({}),          // preserves body extensions when macros stack
    beforeHandle(ctx) {
      const memberRole = readAuthorizedMemberRole(ctx);
      if (!memberRole || !hasMemberPermission(memberRole, permissions)) {
        return ctx.status(403);
      }
      return undefined;
    },
  }));
```

`beforeHandle`, not inside the handler: the 403 must happen before any query,
upload, or external call runs.

### `workspaceAccessMacro` — sub-scope validation

Two variants (`validateWorkspaceAccess`, `...IncludingArchived`), both declaring
`params: t.Object({ workspaceId: tUuid })`, resolving through the already-fetched
access map, and returning **404 (not 403)** when the workspace is absent or in a
disallowed status. 404 does not confirm the resource exists to someone who
cannot see it.

On success they return the branded `workspaceId` plus workspace-bound audit
recorders, so a handler cannot record an event against the wrong scope.

## The bounded membership query

The crux of tenant isolation. Two branches, both `.limit(1)`:

```ts
// No workspace in play — role only.
const row = await db.select({ role: member.role }).from(member)
  .where(and(eq(member.userId, userId), eq(member.organizationId, organizationId)))
  .limit(1).then((rows) => rows.at(0));
```

```ts
// Workspace in play — one query proves membership AND fetches the workspace.
const membershipExists = exists(
  db.select({ id: workspaceMembers.id }).from(workspaceMembers)
    .where(and(
      eq(workspaceMembers.workspaceId, workspaces.id),
      eq(workspaceMembers.userId, member.userId),
    )),
);

const row = await db.select({ role: member.role, workspaceId: workspaces.id, workspaceStatus: workspaces.status })
  .from(member)
  .leftJoin(workspaces, and(
    eq(workspaces.id, workspaceId),
    eq(workspaces.organizationId, member.organizationId),   // <- the isolation
    or(
      membershipExists,
      and(inArray(member.role, ADMIN_BYPASS_ROLES), isNotNull(workspaces.clientId)),
    ),
  ))
  .where(and(eq(member.userId, userId), eq(member.organizationId, organizationId)))
  .limit(1).then((rows) => rows.at(0));
```

`eq(workspaces.organizationId, member.organizationId)` is what stops a membership
in org A from granting access to a workspace in org B. Write a test named
exactly that; it is the single highest-value test in the suite.

The admin bypass lives *inside* the join condition. If it were an early return,
it would skip the org check too.

## Data scoping via RLS

The resolve hands handlers pre-scoped DB handles seeded with
`{ organizationId, serverValidatedWorkspaceIds, userId }`. These set Postgres
session settings that the RLS policies read:

```
app.organization_id, app.user_id, app.workspace_ids, app.workspace_access_mode
```

`serverValidatedWorkspaceIds` contains only workspaces proved in *this* request.
There is a `pinServerValidatedWorkspaceId` operation for the self-removal case:
after a member deletes their own membership row, later statements in the same
transaction still need to complete, so the already-proved ID is pinned rather
than re-derived from a table that no longer contains it.

Two handle flavours: a scoped handle and a `safeDb` variant returning `Result`
for use inside the structured error-handling wrapper.

The connection role used by these handles is a **low-privilege Postgres role**,
distinct from the root role Better Auth uses for session resolution. That is
what makes RLS meaningful — policies do not apply to a superuser.

## Bearer/JWT verification for third-party clients

When a machine client presents a JWT: verify against `/jwks` with both audience
and issuer checks, then require **both** `sub` and the custom tenant claim
(`org_id`). Missing either throws an authentication error. A valid signature is
not authorization; a token without a tenant is not a scoped token.
