# Cloudflare + Supabase Deployment Runbook

This is the target deployment for the XActions Dashboard foundation. It intentionally separates static delivery, edge routing, browser automation, and durable data.

## Services

| Service | Responsibility |
|---|---|
| Cloudflare Pages | Serves the static `dashboard/` site and public routes. |
| Cloudflare Worker | Public API gateway, CORS/auth boundary, rate limits, health checks, and browser-facing realtime transport. |
| Node execution service | Runs the official Express API, Puppeteer/scrapers, workflow engine, background workers, and Socket.IO compatibility layer. |
| Supabase or Prisma Postgres | PostgreSQL persistence through Prisma migrations. |

## One-command local verification

```bash
npm install
npm run db:generate
npm run db:migrate
npm test
npm run start
curl -fsS http://localhost:3001/api/health
```

The exact API port may be changed with the official environment configuration. Do not run migrations against production from a developer laptop without reviewing the generated migration.

## Database deployment

```bash
# Set DATABASE_URL (and DIRECT_URL when the provider requires it)
npm run db:generate
npm run db:migrate:deploy
```

The first foundation migration must be reviewed in `prisma/migrations/` before applying it. Supabase RLS, storage, and auth policies are separate from Prisma schema management and must be added only when a feature requires them.

## Node execution service

Deploy the official `api/` and required `src/` runtime to a Node-compatible host. Render is the fallback documented by the upstream repository; a comparable Node host is acceptable. Configure `DATABASE_URL`, `JWT_SECRET`, `SESSION_SECRET`, `COOKIE_ENCRYPTION_KEY`, `FRONTEND_URL`, and any feature-specific integration secrets. Confirm:

```bash
curl -fsS https://<api-origin>/api/health
```

The API origin must not be an unauthenticated open proxy. Restrict CORS to the Pages origin and Worker origin, enforce request authentication, and keep administrative routes protected.

## Cloudflare Pages

Deploy the existing static dashboard directory as the Pages output. The deployment must preserve the official clean URLs and static assets. Configure the Pages project with the public Worker origin only; do not place private API or database values in Pages variables.

## Cloudflare Worker

The `cloudflare/` directory contains the foundation configuration. Set the Worker `API_ORIGIN` binding to the Node execution service, then deploy from that directory with Wrangler. The Worker health route must be checked before publishing the Pages origin.

```bash
cd cloudflare
npx wrangler deploy
curl -fsS https://<worker-origin>/health
```

The Worker should proxy only the approved `/api/*` surface and provide a browser-safe realtime endpoint. Socket.IO compatibility remains on the Node service; the Worker adapter is the public transport boundary.

## Post-deploy verification

1. Check Worker `/health` and Node `/api/health`.
2. Open every sidebar route and verify the page loads without a console error.
3. Verify authenticated API requests reject missing/invalid sessions.
4. Load a graph fixture and confirm graph data, filters, node selection, and details response.
5. Save and run a workflow fixture; confirm queued, progress, success, and failure events.
6. Confirm a browser receives one realtime event through the Worker transport.
7. Confirm database migrations are applied and no secrets are present in the built dashboard output.
