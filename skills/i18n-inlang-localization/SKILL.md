---
name: i18n-inlang-localization
description: Everything i18n/localization for apps — inlang projects (setup, plugins, validation), translating app messages (machine translation, missing translations, base locale), and the `/translate` slash-command workflow. Triggers on inlang, localization, machine translate, missing translations, locale, baseLocale, plugin-json, i18next, next-intl, ICU message format, /translate.
---

# i18n / Inlang / Localization

| Concern | Section |
|---|---|
| Inlang framework — projects, plugins, validation, ICU message format | [Inlang](#inlang) |
| `/translate` slash command — quick translation workflow | [Translate workflow](#translate-workflow) |

---

# Inlang


# inlang CLI

Automate localization tasks with `@inlang/cli`. Machine translate missing messages, validate configs, and build plugins.

```bash
npx @inlang/cli [command]
```

Minimum Node: v18.0.0. Use `@latest` to ensure current version: `npx @inlang/cli@latest [command]`.

## Project Setup

An inlang project requires a `project.inlang/` folder with `settings.json`:

```
my-app/
├── project.inlang/
│   └── settings.json
├── messages/
│   ├── en.json          # Source language
│   └── de.json          # Translations
└── src/
```

### settings.json

```json
{
  "$schema": "https://inlang.com/schema/project-settings",
  "baseLocale": "en",
  "locales": ["en", "de", "fr"],
  "modules": [
    "https://cdn.jsdelivr.net/npm/@inlang/plugin-json@latest/dist/index.js"
  ],
  "plugin.inlang.json": {
    "pathPattern": "./messages/{locale}.json"
  }
}
```

Supported plugins: JSON, i18next, next-intl, ICU message format.

### Base translation file (messages/en.json)

```json
{
  "greeting": "Hello {name}!",
  "welcome": "Welcome to our app"
}
```

## Quick Reference

| Task | Command |
|------|---------|
| Machine translate all | `npx @inlang/cli machine translate --project ./project.inlang` |
| Translate specific locales | `npx @inlang/cli machine translate --targetLocales sk,zh,pt-BR` |
| Translate (CI, no prompt) | `npx @inlang/cli machine translate -f` |
| Validate project | `npx @inlang/cli validate --project ./project.inlang` |
| Build a plugin | `npx @inlang/cli plugin build --entry ./src/index.ts --outdir ./dist` |
| Build plugin (watch) | `npx @inlang/cli plugin build --entry ./src/index.ts --outdir ./dist --watch` |
| Lint translations | `npx @inlang/cli lint` |
| Open inlang ecosystem | `npx @inlang/cli open [command]` |

## Commands

### machine translate

Translates all missing messages. Uses inlang's free translation service by default; supports Google Cloud Translation for higher reliability.

```bash
npx @inlang/cli machine translate [options]
```

| Option | Description |
|--------|-------------|
| `-f, --force` | Skip confirmation prompt (for CI/CD) |
| `--project <path>` | Path to project root (default: cwd) |
| `--locale <source>` | Base locale override |
| `--targetLocales <targets...>` | Comma-separated target locales (e.g. `sk,zh,pt-BR`) |

### validate

Checks project config is correct.

```bash
npx @inlang/cli validate --project ./path/to/project.inlang
```

| Option | Description |
|--------|-------------|
| `--project <path>` | Path to project root (default: cwd) |

### lint

Lint translation files for issues.

```bash
npx @inlang/cli lint [options]
```

### plugin build

Build an inlang module (plugin development).

```bash
npx @inlang/cli plugin build --entry ./src/index.ts --outdir ./dist
```

| Option | Description |
|--------|-------------|
| `--entry <path>` | Entry point (e.g. `src/index.ts`) |
| `--outdir <path>` | Output directory (default: `./dist`) |
| `--watch` | Watch mode for development |

## CI/CD Integration

Always use `--force` (`-f`) in pipelines to skip interactive prompts:

```bash
npx @inlang/cli machine translate -f --project ./project.inlang
npx @inlang/cli validate --project ./project.inlang
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| "Command not found" | Use `npx @inlang/cli@latest` to get latest version |
| Missing translations after translate | Check `pathPattern` in settings.json matches actual file paths |
| Validation fails | Ensure `project.inlang/settings.json` exists and `modules` URLs are valid |
| Wrong locales translated | Use `--targetLocales` to specify exact targets |
| Node version error | Requires Node v18.0.0+ |
| `m.section_key()` doesn't exist (TS error) | Nested JSON keys require **bracket notation**: `m["section.key"]()` not `m.section_key()`. See Paraglide Naming Gotcha below |
| `oto` locale fails machine translate | Otomi not supported by Google Translate — translate manually or skip |

### Paraglide Naming Gotcha: Nested JSON Keys

**This is the #1 source of errors when migrating from i18next to Paraglide with `plugin-json`.**

When `plugin-json` reads nested JSON:
```json
{ "navbar": { "moreOptions": "More options" } }
```

It flattens to key `"navbar.moreOptions"`. Paraglide then generates:
```js
// Internal variable is lowercased + dedup suffix
const navbar_moreoptions1 = ...
// But the PUBLIC export preserves the original dot-separated key
export { navbar_moreoptions1 as "navbar.moreOptions" }
```

**Correct usage — bracket notation required:**
```tsx
import * as m from "@/paraglide/messages";

// ✅ CORRECT — original key with dots, bracket notation
m["navbar.moreOptions"]()
m["common.back"]()
m["auth.page.emailLabel"]()

// ❌ WRONG — underscore style does NOT exist as an export
m.navbar_moreOptions()    // Property does not exist
m.navbar_moreoptions1()   // Internal name, not exported
```

**Alternative — use `plugin-message-format` with flat keys:**
If you want `m.navbar_share()` style (dot-accessible), use flat underscore keys in your JSON
with `plugin-message-format` instead of `plugin-json`:
```json
{
  "$schema": "https://inlang.com/schema/inlang-message-format",
  "navbar_share": "Share",
  "common_back": "Back"
}
```
This generates `m.navbar_share()` directly — no bracket notation needed.

**Rule of thumb:**
- Nested JSON + `plugin-json` → `m["section.key"]()`
- Flat JSON + `plugin-message-format` → `m.flat_key()`

## Paraglide JS Integration (Vite + React)

Paraglide JS (`@inlang/paraglide-js`) compiles inlang messages into tree-shakeable, type-safe functions. Works with CSR, SSR, and SSG. Tested as part of TanStack's CI/CD pipeline.

### Quick Start

```bash
npx @inlang/paraglide-js@latest init
```

This creates the `project.inlang/` folder and configures your project. Then add the Vite plugin:

```ts
// vite.config.ts
import { paraglideVitePlugin } from '@inlang/paraglide-js'

export default defineConfig({
  plugins: [
    paraglideVitePlugin({
      project: './project.inlang',
      outdir: './src/paraglide',
    }),
    // ... other plugins (tanstackRouter, react, etc.)
  ],
})
```

### Vite Plugin Config (Full)

For localized URLs with locale-prefixed paths:

```ts
paraglideVitePlugin({
  project: './project.inlang',
  outdir: './src/paraglide',
  outputStructure: 'message-modules',
  cookieName: 'PARAGLIDE_LOCALE',
  strategy: ['url', 'cookie', 'preferredLanguage', 'baseLocale'],
  urlPatterns: [
    {
      pattern: '/',
      localized: [
        ['en', '/'],
        ['de', '/de'],
      ],
    },
    {
      pattern: '/about',
      localized: [
        ['en', '/about'],
        ['de', '/de/ueber'],
      ],
    },
    {
      pattern: '/:path(.*)?',
      localized: [
        ['en', '/:path(.*)?'],
        ['de', '/de/:path(.*)?'],
      ],
    },
  ],
})
```

### settings.json for Paraglide

Uses `plugin-message-format` instead of `plugin-json`:

```json
{
  "$schema": "https://inlang.com/schema/project-settings",
  "baseLocale": "en",
  "locales": ["en", "de"],
  "modules": [
    "https://cdn.jsdelivr.net/npm/@inlang/plugin-message-format@4/dist/index.js",
    "https://cdn.jsdelivr.net/npm/@inlang/plugin-m-function-matcher@2/dist/index.js"
  ],
  "plugin.inlang.messageFormat": {
    "pathPattern": "./messages/{locale}.json"
  }
}
```

Message files use `inlang-message-format` schema:

```json
{
  "$schema": "https://inlang.com/schema/inlang-message-format",
  "example_message": "Hello world {username}",
  "home_page": "Home page",
  "about_page": "About page"
}
```

### TanStack Router i18n with URL Rewrites (CSR)

Use the `rewrite` API to de-localize URLs for route matching and re-localize for display:

```tsx
// src/main.tsx
import { createRouter } from '@tanstack/react-router'
import { deLocalizeUrl, localizeUrl } from './paraglide/runtime.js'

const router = createRouter({
  routeTree,
  rewrite: {
    input: ({ url }) => deLocalizeUrl(url),
    output: ({ url }) => localizeUrl(url),
  },
})
```

Handle redirects in root route to prevent infinite redirect loops (required for offline/CSR apps):

```tsx
// src/routes/__root.tsx
import { redirect, createRootRoute } from '@tanstack/react-router'
import { getLocale, setLocale, locales, shouldRedirect } from '@/paraglide/runtime'
import { m } from '@/paraglide/messages'

export const Route = createRootRoute({
  beforeLoad: async () => {
    document.documentElement.setAttribute('lang', getLocale())
    const decision = await shouldRedirect({ url: window.location.href })
    if (decision.redirectUrl) {
      throw redirect({ href: decision.redirectUrl.href })
    }
  },
  component: () => (
    <>
      <Link to="/">{m.home_page()}</Link>
      <Link to="/about">{m.about_page()}</Link>
      {locales.map((locale) => (
        <button key={locale} onClick={() => setLocale(locale)}>
          {locale}
        </button>
      ))}
      <Outlet />
    </>
  ),
})
```

### TanStack Start SSR Integration

For server-side rendering, intercept requests with `paraglideMiddleware`:

```ts
// server.ts
import { paraglideMiddleware } from './paraglide/server.js'
import handler from '@tanstack/react-start/server-entry'

export default {
  fetch(req: Request): Promise<Response> {
    return paraglideMiddleware(req, ({ request }) => handler.fetch(request))
  },
}
```

Set HTML lang attribute in root document:

```tsx
import { getLocale } from '../paraglide/runtime.js'

function RootDocument({ children }: { children: React.ReactNode }) {
  return (
    <html lang={getLocale()}>
      <head><HeadContent /></head>
      <body>
        {children}
        <Scripts />
      </body>
    </html>
  )
}
```

### Typesafe Translated Pathnames

Ensure every route has translations by deriving `urlPatterns` from the generated route tree:

```ts
import { Locale } from '@/paraglide/runtime'
import { FileRoutesByTo } from '../routeTree.gen'

type RoutePath = keyof FileRoutesByTo

function toUrlPattern(path: string) {
  return path
    .replace(/\/\$/, '/:path(.*)?')           // catch-all
    .replace(/\{-\$([a-zA-Z0-9_]+)\}/g, ':$1?') // optional params
    .replace(/\$([a-zA-Z0-9_]+)/g, ':$1')       // named params
    .replace(/\/+$/, '')                          // trailing slash
}

function createTranslatedPathnames(
  input: Record<RoutePath, Record<Locale, string>>,
) {
  return Object.entries(input).map(([pattern, locales]) => ({
    pattern: toUrlPattern(pattern),
    localized: Object.entries(locales).map(
      ([locale, path]) => [locale as Locale, `/${locale}${toUrlPattern(path)}`],
    ),
  }))
}

export const translatedPathnames = createTranslatedPathnames({
  '/': { en: '/', de: '/' },
  '/about': { en: '/about', de: '/ueber' },
})
```

Import `translatedPathnames` into `urlPatterns` in the Paraglide Vite plugin config.

### Prerendering Localized Routes

Use `localizeHref` to generate localized versions for static prerendering. Compile Paraglide before build with the CLI:

```ts
import { localizeHref } from './paraglide/runtime'

export const prerenderRoutes = ['/', '/about'].map((path) => ({
  path: localizeHref(path),
  prerender: { enabled: true },
}))
```

### Key Paraglide APIs

| Import | Purpose |
|--------|---------|
| `m.message_key()` | Access translated message (type-safe) |
| `m.message_key({ var })` | Message with interpolation |
| `getLocale()` | Get current locale |
| `setLocale(locale)` | Switch locale |
| `locales` | Array of available locales |
| `shouldRedirect({ url })` | Check if URL needs locale redirect |
| `deLocalizeUrl(url)` | Strip locale prefix for route matching |
| `localizeUrl(url)` | Add locale prefix for display |
| `localizeHref(path)` | Localize a path for prerendering |
| `paraglideMiddleware(req, handler)` | SSR middleware (from `./paraglide/server.js`) |

### Project Structure (Paraglide)

```
my-app/
├── project.inlang/
│   ├── settings.json
│   ├── project_id         # Auto-generated
│   └── .gitignore          # Contains: cache
├── messages/
│   ├── en.json
│   └── de.json
├── src/
│   ├── paraglide/          # Generated (gitignored)
│   │   ├── runtime.js
│   │   ├── messages.js
│   │   └── server.js       # SSR only
│   ├── routes/
│   │   ├── __root.tsx
│   │   ├── index.tsx
│   │   └── about.tsx
│   └── main.tsx
├── server.ts               # SSR only
└── vite.config.ts
```

### VS Code Extension

Add `.vscode/extensions.json`:

```json
{
  "recommendations": ["inlang.vs-code-extension"]
}
```

## Installation (optional)

```bash
npm install -D @inlang/cli    # project-scoped (recommended)
yarn add --dev @inlang/cli     # yarn alternative
```

Using `npx` without installing is preferred — scopes version to project and works for all team members automatically.

---

# Translate workflow


You are a professional translator. Translate/Synchronize the following MDX content from English to cn.
Preserve all Markdown formatting, code blocks, and component tags. Do not translate code inside code blocks or component names.
Filename for <name>.mdx (English) = <name>.cn.mdx (Chinese)
The content is in .mdx format, which combines Markdown with JSX components.

# Important Notice

1. **Only translate/sync the DIFF** - Compare English source with existing Chinese translation, only update changed parts. DO NOT re-translate the entire file.
2. DO NOT remove any content.
3. You can translate the title markdown ## Plugin Context.

For Example:
<APIItem name="extendApi" type="function">
xxxx content

```ts
(api: (ctx: PlatePluginContext<AnyPluginConfig>) => any) => PlatePlugin<C>;
```

</APIItem>

After translate:
<APIItem name="extendApi" type="function">
xxxx 内容

```ts
(api: (ctx: PlatePluginContext<AnyPluginConfig>) => any) => PlatePlugin<C>;
```

</APIItem>


# How to Determine Which Files Need to Be Updated

Calculate: today's date - last document modification date = days

```bash
./tooling/scripts/list-translate-files.sh [days]
```

Example: today is 2026-01-01, last date is 2025-08-01 → ~153 days

```bash
./tooling/scripts/list-translate-files.sh 153
```

Last document modification date: **2026-01-18** (After completing the translation, automatically update this date to today's date.)
