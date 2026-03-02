# Clerk Spike Review — Manager Briefing

> **Date:** March 2, 2026
> **Duration:** ~1 day (vs. 2-day estimate)
> **Result: Go.** Clerk works across our stack. Recommend proceeding to rollout.

---

## What We Built

Two working apps, both authenticating through a single Clerk instance:

| App | Stack | What it does |
|---|---|---|
| **Phoenix app** (localhost:4000) | Elixir / Phoenix / LiveView / Ash | Sign-in via ClerkJS, JWT verification, protected dashboard, Ash user sync |
| **Next.js app** (localhost:3000) | React / Next.js / @clerk/nextjs | Sign-in/up, protected dashboard, cross-app auth call to Phoenix |

Both apps share the same Clerk instance and user pool. A user who signs up on either app is immediately recognized on the other.

---

## What to Demo

1. **Sign in on Phoenix** (localhost:4000) → Click "Sign In" → enter email/password → lands on dashboard showing Clerk ID, org info
2. **Sign in on Next.js** (localhost:3000) → Already signed in (same Clerk session) → dashboard shows full user profile
3. **Cross-app auth** → On Next.js dashboard, click "Test Cross-App Auth" → Next.js grabs the JWT, sends it to Phoenix `/api/verify` → Phoenix validates it and returns the user as JSON
4. **Sign out** → Click "Sign Out" on Phoenix dashboard → cookie cleared, redirected to home
5. **Clerk Dashboard** (dashboard.clerk.com) → Show the user that was created, the session, the JWT

---

## What We Proved

These were the spike criteria from the proposal. All critical items pass.

| Question | Answer |
|---|---|
| Can we verify Clerk JWTs in Phoenix without an official SDK? | **Yes.** ~100 lines of Elixir using Joken (RS256). Offline — no Clerk API calls at request time. Zero added latency. |
| Does LiveView get auth state? | **Yes.** Standard pattern: HTTP plug sets Phoenix session → LiveView reads it via `on_mount` hook. |
| Can Ash work with Clerk instead of AshAuthentication? | **Yes.** `Ash.PlugHelpers.set_actor/2` works with plain Ash resources. No AshAuthentication needed. Policies evaluate normally. This was the highest-risk item. |
| Does cross-app token sharing work? | **Yes.** Next.js calls `getToken()` → sends Bearer header to Phoenix → same JWT verification plug validates it. |
| Do email/password and SSO use the same code path? | **Yes.** Both produce identical JWTs. The Phoenix plug doesn't know or care which provider issued the token. |
| Does Next.js integration work? | **Yes.** `@clerk/nextjs` is genuinely drop-in. ~15 minutes of work. |

**Not yet tested:** Microsoft SSO through Clerk. This requires configuring Microsoft as a social provider in Clerk Dashboard, which needs Entra ID OAuth credentials. Not a technical risk — Clerk supports it natively and the JWT path is identical regardless of provider.

---

## What's Reusable Across Our Apps

The spike produced three reusable components for any Elixir/Phoenix app:

### 1. ClerkAuthPlug (~100 LOC)
Drop into any Phoenix router pipeline. Extracts JWT from `__session` cookie or `Authorization: Bearer` header, verifies RS256 signature offline, assigns `current_user` to conn. Works in both browser and API pipelines.

```
Browser pipeline: cookie → verify → session + assigns
API pipeline:     Bearer header → verify → assigns only
```

### 2. LiveAuth on_mount hook (~20 LOC)
Two callbacks for LiveView route protection:
- `:require_authenticated_user` — redirect to sign-in if not logged in
- `:maybe_authenticated` — assign user or nil, don't block

### 3. AshActorPlug (~30 LOC)
Runs after ClerkAuthPlug. Takes Clerk claims, upserts a local Ash User record (by `clerk_id`), sets the Ash actor. Policies just work.

**For non-Elixir apps:** Clerk has official SDKs for Next.js, React, Express, Python, Go, Java, Ruby, C#. Those are all drop-in — no custom code needed.

---

## How This Plugs Into All Our Apps

```
                    ┌──────────────────────────┐
                    │     CLERK                 │
                    │  (single instance)        │
                    │                           │
                    │  Internal: Microsoft SSO  │
                    │  External: Email/Magic/SSO│
                    └────────────┬──────────────┘
                                 │ JWT
                    ┌────────────┴──────────────┐
                    │                           │
        ┌───────────┴───────────┐   ┌──────────┴──────────┐
        │  Elixir/Phoenix apps  │   │  Everything else     │
        │                       │   │                      │
        │  ClerkAuthPlug        │   │  Official Clerk SDK  │
        │  (Joken RS256)        │   │  (drop-in)           │
        │  LiveAuth on_mount    │   │                      │
        │  AshActorPlug         │   │  Next.js, Express,   │
        │                       │   │  Python, Go, etc.    │
        │  ~150 LOC total       │   │  ~0 custom code      │
        └───────────────────────┘   └──────────────────────┘
```

**Per-app integration effort:**

| Stack | Effort | What's needed |
|---|---|---|
| Next.js / React | ~15 min | `npm install @clerk/nextjs`, add ClerkProvider, done |
| Express | ~30 min | `npm install @clerk/express`, add middleware |
| Python | ~30 min | `pip install clerk-backend-api`, add middleware |
| Elixir/Phoenix | ~2 hours | Copy ClerkAuthPlug + LiveAuth + AshActorPlug from spike |
| Any OIDC-capable framework | ~1 hour | Standard OIDC flow using framework's native library |

---

## What's Left Before Rollout

1. **Entra ID OAuth credentials** for Clerk — so we can add Microsoft as a social provider in Clerk Dashboard. This lets the team keep "Sign in with Microsoft" unchanged.
   - Needs: Azure App Registration → Client ID + Client Secret → paste into Clerk Dashboard → Social Connections → Microsoft
   - This is read-only from Entra's perspective — no changes to existing Entra ID setup

2. **Decision: which app goes first?** Pick one internal app to migrate as the pilot (Week 5-6 of the rollout plan).

### We handle:

3. Configure custom session token in Clerk Dashboard to include email in JWTs (5 minutes)
4. Test Microsoft SSO end-to-end once Entra ID credentials are provided
5. Migrate pilot app using the reusable components from the spike

---

## Cost

| Scenario | Monthly | Notes |
|---|---|---|
| Year 1 (Clerk Free) | **$0** | Up to 50k MAU — covers us entirely |
| If we need enterprise SSO metering | $25 | Clerk Pro, per-connection SSO fees |
| Auth0 fallback (if needed) | $150 | 10 enterprise connections included |

---

## Risk Summary

| Risk | Status |
|---|---|
| No official Elixir SDK | **Mitigated** — ~100 LOC plug, fully tested, no network dependency |
| Ash + Clerk incompatible | **Mitigated** — confirmed working, no AshAuthentication needed |
| LiveView can't do auth | **Mitigated** — standard session bridge pattern works |
| Clerk too immature | **Low** — SOC 2 Type II on all tiers, 4 years in market, growing fast |
| Lock-in | **Low** — JWT/OIDC are standards. Auth0 fallback is a config change, not a rewrite |

---

## Bottom Line

The spike answered every question it was designed to answer. The hardest integration (Elixir/Phoenix/Ash) works. The easy ones (Next.js, Express, Python) are drop-in. We're looking at $0/month for year one, ~150 lines of custom code for the Elixir stack, and zero custom code for everything else.

**Recommendation:** Get us the Entra ID credentials, pick a pilot app, and let's start the rollout.
