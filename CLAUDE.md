# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

Technical spike validating Clerk as a centralized authentication broker across a mixed technology stack. Contains two proof-of-concept apps and strategic documentation.

The core question: Can Clerk replace direct Microsoft Entra ID integration to support both internal team (Microsoft SSO) and external client authentication (email/password, magic link, federated SSO)?

## Repository Structure

```
clerk-poc-spike/
├── docs/
│   ├── PROPOSAL.md        — Business case, provider comparison, cost analysis
│   ├── SPIKE_PLAN.md      — 2-day technical spike plan
│   └── FINDINGS.md        — Spike results and go/no-go recommendation
├── apps/
│   ├── phoenix_app/       — Elixir/Phoenix/LiveView/Ash (critical path)
│   └── nextjs_app/        — React/Next.js with @clerk/nextjs
├── .env.example           — Required environment variables
└── CLAUDE.md
```

## Key Documents

- `docs/PROPOSAL.md` — Business case, provider comparison (Clerk vs Auth0), cost analysis, rollout timeline
- `docs/SPIKE_PLAN.md` — 2-day technical spike plan for validating Clerk with Elixir/Phoenix/LiveView/Ash
- `docs/FINDINGS.md` — Spike results, go/no-go matrix, reusable code patterns

## Architecture Context

**Auth flow:** ClerkJS (frontend) issues JWT in `__session` cookie → Phoenix Plug verifies JWT via Joken (RS256) → verified user stored in Phoenix session → LiveView reads user via `on_mount` hook.

**The hard problem:** Clerk has no official Elixir SDK. The spike validates manual JWT verification with Joken/JOSE and whether AshAuthentication can be bypassed in favor of Clerk-issued tokens.

**Fallback:** Auth0 + `ueberauth`. Both providers use standard OIDC, so switching is a config change.

## Build / Test / Run Commands

### Phoenix App

```bash
cd apps/phoenix_app
mix deps.get
mix ecto.create
mix ecto.migrate
mix test                    # Run all tests
mix test test/path_test.exs # Run specific test file
mix phx.server              # Start dev server on port 4000
```

### Next.js App

```bash
cd apps/nextjs_app
npm install
npm run dev     # Start dev server on port 3000
npm run build   # Production build
npm run lint    # Lint check
```

### Environment Setup

Copy `.env.example` to `.env` and fill in Clerk credentials from clerk.com dashboard.

## Target Stack

- **Elixir/Phoenix/LiveView/Ash** — most complex integration, focus of the spike
- **React/Next.js** — Clerk has drop-in SDK support
- Key Elixir dependencies: `joken` (~> 2.6), `jose` (~> 1.11), `req` (~> 0.5), `ash` (~> 3.0), `clerk` (~> 1.2)

## Important Implementation Notes

- Use `Application.get_env/3` for Clerk config at **runtime**, NOT `@module_attribute System.get_env(...)` (compile-time bug in SPIKE_PLAN.md)
- ClerkJS containers in LiveView templates must use `phx-update="ignore"` to prevent DOM conflicts
- After Clerk sign-in, do a full page redirect (not LiveView push) so the HTTP plug reads the new `__session` cookie
- Mise is used for Elixir/Erlang version management (see `mise.toml`)

## Spike Decision Criteria

The spike succeeds if all of these pass:
1. Microsoft SSO flows through Clerk into Phoenix
2. JWT verification works in a Phoenix Plug
3. LiveView inherits auth via session bridge (on_mount hook)
4. Ash actor can be set from Clerk-verified user without breaking policies
5. External client email/password uses the same path as internal SSO
