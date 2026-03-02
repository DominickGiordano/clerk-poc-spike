# Clerk POC Spike

Technical spike validating [Clerk](https://clerk.com) as a centralized authentication broker across a mixed technology stack (Elixir/Phoenix/LiveView/Ash + React/Next.js).

**Core question:** Can Clerk replace direct Microsoft Entra ID integration to support both internal team (Microsoft SSO) and external client authentication (email/password, magic link, federated SSO)?

## Quick Start

### Prerequisites

- Elixir 1.18+ / Erlang 27+ (managed via [mise](https://mise.jdx.dev/) — see `mise.toml`)
- Node.js 20+
- PostgreSQL 16+
- A [Clerk](https://clerk.com) account (free tier)

### 1. Clone and configure

```bash
cp .env.example .env
# Fill in your Clerk credentials from https://dashboard.clerk.com
```

### 2. Phoenix app

```bash
cd apps/phoenix_app
mix deps.get
mix ecto.create
mix ecto.migrate
mix test              # 23 tests, 0 failures
mix phx.server        # http://localhost:4000
```

### 3. Next.js app

```bash
cd apps/nextjs_app
npm install
npm run dev           # http://localhost:3000
npm run build         # Requires NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
```

## Repository Structure

```
clerk-poc-spike/
├── docs/
│   ├── PROPOSAL.md        — Business case, Clerk vs Auth0, cost analysis
│   ├── SPIKE_PLAN.md      — 2-day spike plan with actual outcomes
│   └── FINDINGS.md        — Results, go/no-go matrix, reusable code patterns
├── apps/
│   ├── phoenix_app/       — Elixir/Phoenix/LiveView/Ash (critical path)
│   └── nextjs_app/        — React/Next.js with @clerk/nextjs
├── .env.example           — Required environment variables
└── CLAUDE.md              — AI assistant context
```

## Architecture

```
User signs in via ClerkJS (frontend)
  → Clerk issues __session JWT cookie
  → Phoenix Plug verifies JWT (RS256 via Joken, offline)
  → Verified user stored in Phoenix session
  → LiveView reads user via on_mount hook
  → Ash actor set via Ash.PlugHelpers.set_actor/2
```

Cross-app: Next.js calls `getToken()` → sends Bearer token to Phoenix `/api/verify` → same JWT verification plug.

## Key Findings

- **Ash + Clerk coexistence confirmed** — `Ash.PlugHelpers.set_actor/2` works with plain Ash resources, no AshAuthentication needed
- **JWT verification is ~100 LOC** — offline (no Clerk API calls at request time), fully tested, works in both browser and API pipelines
- **Next.js integration is trivial** — `@clerk/nextjs` is genuinely drop-in
- **Community `clerk` Hex package not needed** — manual Joken approach is simpler with no network dependency
- **Cross-app auth works** — Next.js `getToken()` → Bearer header → Phoenix `/api/verify` returns verified user
- **Clerk default JWT omits email** — requires custom session token config in Clerk Dashboard

**Recommendation: Go.** See [docs/FINDINGS.md](docs/FINDINGS.md) for the full analysis.

## Integration Test Results

Tested with live Clerk free-tier instance.

| Test | Result |
|---|---|
| Email/password sign-up | **Pass** |
| Email/password sign-in (Phoenix) | **Pass** |
| Email/password sign-in (Next.js) | **Pass** |
| Cross-app auth (Next.js → Phoenix) | **Pass** |
| Sign-out (Phoenix) | **Pass** |
| Sign-out (Next.js) | **Pass** |
| Microsoft SSO | Not tested (needs Entra ID config) |

## Related Docs

- [PROPOSAL.md](docs/PROPOSAL.md) — Why Clerk, why not Auth0/Kinde/Keycloak, rollout timeline
- [SPIKE_PLAN.md](docs/SPIKE_PLAN.md) — Original 2-day plan with post-spike outcomes
- [FINDINGS.md](docs/FINDINGS.md) — Go/no-go matrix, code patterns, risks, cost projection
