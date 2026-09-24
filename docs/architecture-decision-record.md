# XActions Dashboard — Architecture Decision Record

**Status:** Accepted for Task 1 foundation  
**Date:** 2026-09-24  
**Repository baseline:** `nirholas/XActions` at commit `24eed62ec87de80d33d280dce081f9ccea5c0ba8`  
**Scope:** Repository analysis and foundation only; feature implementation follows in later tasks.

## Decision summary

Extend the official XActions repository instead of creating a parallel dashboard. Keep the official static dashboard markup, page URLs, API route vocabulary, workflow action registry, scraper/runtime modules, and existing Prisma models as the compatibility baseline. Add a typed persistence boundary for the two priority surfaces—Social Graph and Workflows—and deploy the presentation layer at Cloudflare Pages, an edge gateway/realtime layer on Cloudflare Workers, and the stateful PostgreSQL layer on Supabase or Prisma Postgres.

The official execution runtime remains Node-compatible. This is intentional: browser automation, Puppeteer-based scraping, filesystem fallbacks, and several existing workers cannot execute unchanged inside a Cloudflare Worker. The Cloudflare Worker therefore owns edge concerns (routing, auth/session verification, CORS, rate limits, SSE/WebSocket-compatible realtime fan-out, and API proxying), while the existing API/worker runtime performs XActions operations. Render is the fallback host for that Node runtime when a Cloudflare-compatible Node host is not available.

## Repository findings

| Area | Current official implementation | Foundation decision |
|---|---|---|
| Dashboard | `dashboard/` is a static, multi-page site with shared CSS/JS and no frontend build step. | Preserve URLs and shared assets; introduce shared state/error primitives incrementally rather than rewriting all pages. |
| API | `api/` is an Express API with route modules under `api/routes/`, services under `api/services/`, and OpenAPI metadata in `api/openapi.js`. | Keep route contracts; place the Worker in front of the API and add adapters where edge-safe behavior is required. |
| Persistence | `prisma/schema.prisma` uses PostgreSQL and `DATABASE_URL`. Workflow storage can fall back to JSON files and can also use `Operation` rows. | Use Supabase/Prisma Postgres as the production source of truth; add explicit graph/workflow/run/event models. |
| Workflow execution | `src/workflows/actions.js`, `engine.js`, `conditions.js`, `triggers.js`, and `store.js` provide reusable actions, conditions, scheduled/event triggers, and run persistence. | Reuse the action registry and engine. The visual builder serializes to this existing definition format. |
| Social Graph | Dashboard route `/graph`, API graph routes, graph docs, and graph/MCP analysis utilities already exist. | Keep graph API vocabulary; use dedicated normalized nodes/edges plus stored influence/cluster values for D3 rendering. |
| Realtime | Official docs specify Socket.IO events including `operation:progress`, `graph:complete`, and `stream:data`; the repository contains Socket.IO server/client usage in its Node services. | Standardize event envelopes and expose a Cloudflare-compatible Worker fan-out boundary. Socket.IO remains supported for Node clients; browser dashboard uses an edge-safe stream adapter. |
| Deployment | Official docs cover Cloudflare Pages for dashboard and Node hosts including Railway, Fly, Render, and Docker. | Cloudflare Pages + Worker gateway + Supabase/Prisma Postgres is the primary target; Render is the documented fallback for browser execution. |

## Official dashboard design system extracted

The baseline is a dark, X-inspired interface. The primary tokens found in `dashboard/css/common.css` and related files are:

| Token | Value / behavior |
|---|---|
| Primary background | `#0a0a0f` (`--bg-primary`) |
| Secondary/card surfaces | `#131722`, `#1a1e2e`, and `--bg-tertiary` for elevated controls |
| Accent | `#1d9bf0` (`--accent`), with `--grad` for accent gradients |
| Text | `--text-primary`, `--text-secondary`, muted text for supporting metadata |
| Status | `--success`, `--error`, and warning/status variants |
| Borders | `--border` and `--border-glow` |
| Shadows | `--shadow-1` and `--shadow-2` for cards and CTA surfaces |
| Typography | System stack: `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto` |
| Motion | `--ease` plus short transitions; focus-visible outline uses the accent |
| Breakpoints | 768px for compact sidebar/mobile behavior and 1024px for right-rail removal |
| Top navigation | 53px fixed bar, translucent black background, 12px blur, pill links |

The primary dashboard layout has a left sidebar, a central main content column, and an optional right rail. At widths below 1024px the right rail disappears; below 768px the left sidebar collapses to an icon rail. The official CSS includes skip navigation and visible keyboard focus styles; those are baseline accessibility requirements for new pages.

## Official sidebar route map

The main dashboard sidebar in `dashboard/index.html` currently exposes these operational links:

| Category | Routes |
|---|---|
| Operations | `/run`, `/scripts`, `/features`, `/automations`, `/workflows`, `/agent`, `/monitor`, `/unfollowers` |
| Content | `/video`, `/thread`, `/thread-composer`, `/calendar` |
| AI and protocols | `/mcp`, `/a2a`, `/ai`, `/ai-api` |
| Analytics | `/analytics-dashboard`, `/analytics`, `/price-correlation`, `/graph` |
| Integrations and administration | `/integrations`, `/team`, `/admin`, `/login` |
| Information and support | `/docs`, `/tutorials`, `/blog`, `/use-cases`, `/compare`, `/pricing`, `/faq`, `/changelog`, `/contact`, `/status`, `/about` |

The docs page inventory also includes the public policy routes `/privacy`, `/terms`, `/security`, and `/contributing`. No route will be removed while the new dashboard is built; route registration and link audits will be part of every feature task.

## Chosen target stack

### Presentation

The current static HTML/CSS/JavaScript dashboard remains the compatibility layer. New high-interaction surfaces may use isolated ES modules and D3/React Flow-compatible client code, but the first implementation should not force a full application rewrite. Static assets are deployed to Cloudflare Pages.

### Edge and realtime

A Cloudflare Worker is the single public API origin for the dashboard. It will validate sessions, apply origin and rate-limit policy, proxy safe API requests to the Node execution service, and provide a Cloudflare-compatible stream for operation progress, graph completion, workflow run updates, and stream events. Durable Objects or another Cloudflare-native coordination primitive will be selected during realtime implementation if cross-instance fan-out is required; the browser contract will be an event envelope independent of the transport.

### Execution

The official Express API and `src/` runtime remain the execution layer. Puppeteer, scraping adapters, workflow actions, filesystem fallbacks, and job workers run in a Node-compatible service. This avoids pretending that browser automation can be bundled into a Worker. The service is stateless at the request layer and uses Supabase/Postgres for durable state.

### Database

Prisma remains the schema and migration tool. The datasource is PostgreSQL through `DATABASE_URL`, which supports Supabase pooled/direct connection strings and Prisma Postgres connection strings. Production migrations run with `prisma migrate deploy`; local development may use `prisma migrate dev` or `prisma db push` only for disposable databases.

New first-class models are `SocialGraph`, `SocialGraphNode`, `SocialGraphEdge`, `Workflow`, `WorkflowRun`, and `RealtimeEvent`. JSON columns are represented as strings to match the official schema/runtime convention and to preserve compatibility with the existing JS code; API adapters will validate and parse them at the boundary.

### Authentication and secrets

Secrets remain server-side. The dashboard receives only public configuration such as the Worker origin and a public Supabase URL/key when a browser-side Supabase feature is explicitly needed. X session cookies, OAuth client secrets, JWT/session signing keys, database URLs, and service-role keys are never committed or shipped to Pages. The canonical environment contract is documented in `docs/environment.md`.

## Realtime contract

All transports use the following logical event envelope:

```json
{
  "id": "event-id",
  "topic": "workflow:run-id",
  "type": "operation:progress",
  "occurredAt": "2026-09-24T00:00:00.000Z",
  "requestId": "request-id",
  "payload": {}
}
```

Required event types for the first implementation are `operation:progress`, `operation:completed`, `operation:error`, `graph:progress`, `graph:complete`, `workflow:run`, `workflow:step`, `workflow:complete`, `workflow:error`, and `stream:data`. The event log is persisted only for durable workflow/run audit needs; transient high-volume stream data must not be written unboundedly to Postgres.

## Social Graph foundation

The graph API returns a graph identifier, node and edge collections, filters, cluster identifiers, influence values, and a stable selected-node detail shape. D3 owns the client-side force simulation, zoom/pan, clustering visibility, influence sizing, filtering, hover/focus, keyboard selection, and details panel. The database stores normalized graph nodes/edges and computed influence/cluster values so the visualization can reload and remain deterministic across sessions.

## Workflow foundation

The visual builder is a client representation of the existing workflow definition consumed by `src/workflows/engine.js`. Nodes map to registered action names from `src/workflows/actions.js`; edges map to sequence/condition branches; trigger metadata maps to `src/workflows/triggers.js`; conditions map to `src/workflows/conditions.js`. The server validates definitions before persisting or executing them. Every run has a durable `WorkflowRun` row and emits the realtime event envelope above.

## Alternatives considered

| Approach | Tradeoffs | Cost profile | Setup complexity |
|---|---|---|---|
| **Chosen: Cloudflare Pages + Worker gateway + Node execution service + Supabase/Postgres** | Best fit for static global delivery and edge routing while preserving Puppeteer and existing JS runtime. Requires two deploy targets and explicit proxy/realtime contracts. | Pages/Worker usage plus database and Node host; avoids rewriting the execution engine. | Medium; clear boundaries and scripted deployments. |
| Full Cloudflare Worker rewrite | Excellent edge footprint, but incompatible with Puppeteer/browser automation, filesystem assumptions, and several Node dependencies. High rewrite and regression risk. | Low edge cost but high engineering cost. | High. |
| Single Node service serving `dashboard/` and `/api` | Lowest short-term change and easiest Socket.IO support, but weaker global delivery and less Cloudflare leverage. | One host plus database. | Low. |
| Static Pages + direct browser-to-Supabase | Simple for read-heavy pages, but unsuitable for X session secrets, privileged operations, workflow execution, and consistent authorization. | Low infrastructure cost, higher security risk if misused. | Low initially, unacceptable for privileged features. |

## Foundation structure

```text
XActions/
├── dashboard/                 # official static pages, shared CSS/JS, data
├── api/                       # official Express API and Node execution services
├── src/                       # official scrapers, workflows, agents, CLI, MCP
├── prisma/                    # PostgreSQL schema, migrations, seed
├── cloudflare/                # Worker gateway foundation and deployment config
├── docs/
│   ├── architecture-decision-record.md
│   ├── environment.md
│   └── deployment-cloudflare-supabase.md
├── .env.example               # existing official env contract; no secrets
└── package.json               # official scripts plus deploy-safe Prisma commands
```

## Consequences and follow-up gates

This decision deliberately favors compatibility over a wholesale frontend rewrite. Later tasks must add feature-level loading, empty, error, and success states; validate all API responses at boundaries; test the graph with deterministic fixtures; test workflow definitions and execution failures; audit links; run the official test suite; and verify the Pages/Worker/Node deployment path with health checks. A deployment is not considered complete until the Worker can reach the Node API, the API can reach the configured Postgres database, and a browser can receive at least one realtime event.

## Verification performed for this ADR

The official repository was cloned cleanly at the commit listed above. The dashboard tree, `dashboard/index.html`, shared CSS, `docs/dashboard.md`, `docs/deployment.md`, `prisma/schema.prisma`, `src/workflows/*`, API route tree, package manifest, and environment example were inspected. The baseline was confirmed to have no root TypeScript project; therefore the official root remains JavaScript and TypeScript is reserved for the new Worker boundary when it is implemented with its own config.

## Known risks

The official repository contains a broad and evolving feature surface, multiple optional providers, and Node-only scraping paths. Cloudflare cannot replace the Node runtime without a significant rewrite. Supabase connection pooling and long-running job behavior must be tested under production limits. Socket.IO cannot be assumed to run directly inside a stateless Worker; the browser-facing transport adapter and coordination primitive must be implemented and verified in the realtime task. Existing `Operation`-based workflow records should be migrated carefully rather than deleted.
