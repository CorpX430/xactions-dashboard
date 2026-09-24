# Environment and Secret Contract

This repository uses the official `.env.example` as the starting point. Copy it to `.env` only for local development; never commit `.env` or production secret values.

## Required production variables

| Variable | Runtime | Purpose |
|---|---|---|
| `DATABASE_URL` | Node API, migration job | Supabase pooled or Prisma Postgres connection string. Use the pooled URL for request traffic and the direct URL for migrations when Supabase recommends it. |
| `DIRECT_URL` | Prisma migrations | Optional direct PostgreSQL URL for migration operations when the provider exposes a separate direct connection. |
| `JWT_SECRET` | Node API / Worker verifier | Session signing and verification secret. Generate with `openssl rand -hex 32`. |
| `SESSION_SECRET` | Node API | Session encryption/signing fallback. Generate independently. |
| `COOKIE_ENCRYPTION_KEY` | Node API | AES-256-GCM key for stored X session cookies. Prefer a dedicated key. |
| `FRONTEND_URL` | Node API | Canonical Pages origin used for CORS and callback validation. |
| `API_ORIGIN` | Cloudflare Worker | Private/public origin of the Node execution API. |
| `CLOUDFLARE_ACCOUNT_ID` | Deployment only | Cloudflare account target. Store in CI/provider secrets, not in the client. |
| `CLOUDFLARE_API_TOKEN` | Deployment only | Scoped deployment token. Never expose to Pages runtime code. |

## Optional integrations

`TWITTER_CLIENT_ID`, `TWITTER_CLIENT_SECRET`, `TWITTER_BEARER_TOKEN`, `XACTIONS_SESSION_COOKIE`, `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`, `ADMIN_API_KEY`, `SENTRY_DSN`, and `LOG_LEVEL` remain server-side and are only required by the features that use them. Supabase browser variables, if later needed, must be named with the dashboard build system's public prefix and must never contain a service-role key.

## Secret rules

The Worker may receive secrets through encrypted deployment bindings. Pages receives only non-sensitive public configuration. Database service-role keys, X session cookies, OAuth client secrets, JWT/session keys, Redis credentials, and admin keys must not appear in HTML, dashboard JavaScript, logs, error payloads, screenshots, or Git history. Rotate any value that is accidentally exposed.

## Local setup

```bash
cp .env.example .env
# Edit only the values required for the feature under development.
npm install
npm run db:generate
npm run db:migrate
npm run dev
```

For a disposable local database, `npm run db:push` is acceptable. For Supabase or any shared database, review the migration and use `npm run db:migrate:deploy`.
