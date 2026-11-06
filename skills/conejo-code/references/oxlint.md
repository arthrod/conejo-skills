# Oxlint and oxfmt

House lint and format for TypeScript and JavaScript. Not biome, not eslint, not prettier. Read this before adding or changing a lint or format config.

Worked example: `live-contracts/frontend` (`.oxlintrc.json`, `.oxfmtrc.json`, `test/tsconfig.json`). Verified 2026-11-06: `pnpm exec oxlint --deny-warnings src test` → 0 warnings, 0 errors, 32 files, 134 rules.

## Install and scripts

```bash
pnpm add -D oxlint oxlint-tsgolint oxfmt
```

Astro formatting also needs `@astrojs/compiler-rs`. Oxfmt does not bundle it. Formatting `.astro` fails without it.

```json
{
  "scripts": {
    "lint": "oxlint",
    "fmt": "oxfmt",
    "fmt:check": "oxfmt --check"
  }
}
```

Run lint as `pnpm exec oxlint --deny-warnings src test` (name the roots). `--deny-warnings` makes warnings fail the process. `pnpm check` is oxlint only when that script says so. In an Astro app it is often `astro check`, which is a different checker.

## `.oxlintrc.json`

Put it next to `package.json`. Point `$schema` at `./node_modules/oxlint/configuration_schema.json`.

```json
{
  "$schema": "./node_modules/oxlint/configuration_schema.json",
  "plugins": ["eslint", "typescript", "unicorn", "oxc", "import", "vitest", "promise"],
  "categories": { "correctness": "error" },
  "options": { "typeAware": true, "typeCheck": true }
}
```

### Plugins replace the defaults

Setting `plugins` overwrites the base set. The array must be every plugin you want, not the extras.

Restate the base: `eslint`, `typescript`, `unicorn`, `oxc`. Add `import`, `vitest`, and `promise` for this stack (Vitest, ESM, Workers). Leave off `react`, `jsx-a11y`, `nextjs`, `react-perf`, `vue`, `jest`, `node`, and `jsdoc` unless the project actually uses that framework or test runner.

`--print-config` may omit the name `eslint` from the resolved plugin list. `eslint(...)` diagnostics still run. Keep `eslint` in the array anyway.

### Typechecker

`options.typeAware` enables the typescript-eslint rules that need types. `options.typeCheck` reports TypeScript diagnostics. Both need the `oxlint-tsgolint` package. `typeCheck` is marked experimental by oxlint.

Each file uses the nearest `tsconfig`. IF the app `tsconfig` excludes `test/` THEN the typechecker cannot see `cloudflare:test`, `import.meta.glob`, or `*?raw` until you add `test/tsconfig.json` that extends the parent and includes the tests. A child's `compilerOptions.types` replaces the parent's, so restate `@cloudflare/workers-types` and add `@cloudflare/vitest-pool-workers/types`. Do not put `vite/client` in `types` unless `vite` is a direct dependency. The compiler looks for a package named `vite/client` and fails with "Cannot find type definition file". Declare `import.meta.glob` and `declare module '*?raw'` in `test/vite-env.d.ts` instead.

`typescript/triple-slash-reference` fires on Astro's `src/env.d.ts`. Turn that rule off for that file only. Do not delete the `/// <reference`.

### Astro

Oxlint has no Astro plugin. It lints frontmatter and `<script>` only. The template is invisible, so `jsx-a11y` cannot cover the markup.

The Astro configuration is an env override plus `no-undef`. `categories.correctness` does not include `no-undef`. A green lint with the rule off does not mean `Astro` is defined.

```json
{
  "files": ["**/*.astro"],
  "env": { "builtin": true, "astro": true, "browser": true },
  "rules": { "eslint/no-undef": "error" }
}
```

`env.astro` defines `Astro`. `env.browser` defines `document`, `window`, `localStorage`, `fetch`, `navigator`. Put `builtin` in the override too so the override does not drop it.

`define:vars={{ NAME }}` injects `NAME` into that inline script. Oxlint does not see the injection. Declare `NAME` as a `"readonly"` global on that page. A later override merges. It does not clear the `**/*.astro` env.

Globs: `[page]` is a character class. The pattern `src/pages/agreements/[page].astro` does not match a file of that name. Use `src/pages/agreements/*.astro`, or escape the brackets.

`ignorePatterns` entry `.astro` ignores the generated `.astro/` directory. It does not ignore `*.astro` sources. Do not "fix" a noisy Astro file by adding `.astro` to ignores.

### Workers, Node, Vitest

`env.serviceworker` and `env.worker` are web workers. They are not Cloudflare Workers. Oxlint has no Workers environment. Leave `eslint/no-undef` off for Worker TypeScript. Turning it on flags real Worker globals: `Response`, `Request`, `console`, `crypto`, `fetch`, `URL`, `TextEncoder`, `Blob`. It also flags `process` in Node scripts.

Node scripts (`.mjs`) need `env.node` before `no-undef`. Tests that call `describe` as a global need `env.vitest`. This house imports from `vitest`, so the vitest plugin is enough and `env.vitest` stays off.

## oxfmt

`.oxfmtrc.json`, schema `./node_modules/oxfmt/configuration_schema.json`.

Match the code oxfmt can actually express: single quotes, semicolons, 2-space indent, trailing commas `"all"`, `bracketSpacing`, `arrowParens` `"always"`, `objectWrap` `"preserve"`, `printWidth` 120. 120 sits near the p95 of existing TypeScript. The maximum oxfmt accepts is 320.

```json
{
  "astro": { "compressHTML": "none" },
  "sortPackageJson": false,
  "ignorePatterns": ["dist", "node_modules", ".astro", ".wrangler", "**/*.css"]
}
```

The `astro` key turns on the Astro formatter. `compressHTML: "none"` stops it injecting `{' '}` text nodes. Leave `sortImports` and `jsdoc` off. `sortImports` rewrites import order. `sortPackageJson` defaults to on, so set it `false`.

Ignore `**/*.css`. Oxfmt lowercases hex colors and destroys hand-aligned columns. No legal `printWidth` preserves them.

oxfmt also cannot keep, at any width:

- packed multi-property objects (a multi-line object becomes one property per line)
- one-line `try { } catch { }`
- some short method chains that contain a newline inside a regex

Do not `oxfmt --write` a dense file just to clear a lint. Format the files that already match this config. `pnpm fmt` on a dense tree will rewrite it. That rewrite is the tool, not a wrong width.

## Prove the config

1. `pnpm exec oxlint --print-config` and read `plugins`, `options.typeAware`, `options.typeCheck`.
2. `pnpm exec oxlint --deny-warnings src test`.
3. For Astro, confirm `Astro` is not reported under the `**/*.astro` override. IF you skip step 3 THEN a clean run does not prove the env.
