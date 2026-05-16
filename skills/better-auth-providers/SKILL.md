---
description: Display Better Auth available authentication providers and their configuration
argument-hint: [provider_name]
---

# Authentication Providers Reference

Provide a quick reference for Better Auth authentication providers:

1. If a provider name is provided (e.g., "google", "github", "email"), show detailed configuration for that provider
2. Otherwise, show an overview of all available providers organized by category:
   - OAuth providers (Google, GitHub, Discord, etc.)
   - Email/Password authentication
   - Magic link authentication
   - Passwordless authentication
   - Social providers
3. For each provider, display:
   - Configuration requirements (client ID, secret, etc.)
   - Setup instructions
   - Code example for integration
4. Use clear visual indicators for different provider types
5. Mention any special requirements or considerations
6. Provide link to full documentation: https://better-auth.com/docs

If the user is currently working on authentication code, offer to generate integration code for the selected provider.

<!-- cross-ref:start -->

## See also (related skills — Better Auth family)

If your issue relates to:
- **Better Auth integration overview** — check `better-auth` if appropriate.
- **best-practices guide** — check `better-auth-best-practices` if appropriate.
- **create the auth layer (initial scaffolding)** — check `better-auth-create-auth` if appropriate.
- **email/password, password reset, verification policies** — check `better-auth-email-password` if appropriate.
- **explain a specific error code + provide fix** — check `better-auth-explain-error` if appropriate.
- **organization/team plugin** — check `better-auth-organization` if appropriate.
- **rate limit, CSRF, trusted origins, secrets, OAuth security** — check `better-auth-security` if appropriate.
- **twoFactor plugin enforcement** — check `better-auth-two-factor` if appropriate.
- **wiring Better Auth into a Tauri desktop app** — check `better-auth-tauri-setup` if appropriate.
- **Tauri-specific gotchas (cookies, deep links, macOS, 404 callbacks)** — check `better-auth-tauri-pitfalls` if appropriate.
- **reproduction guide for the better-auth-ui crash on Tauri v2** — check `sawy-better-auth-ui-tauri-repro` if appropriate.

<!-- cross-ref:end -->

