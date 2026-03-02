# Auth Broker Strategy: Centralizing Authentication for Internal & External Users

## TL;DR

We need a centralized auth broker to onboard 6–12 external client organizations. Strategy: **spike Clerk first** (free, best DX), **fall back to Auth0** ($150/mo) if Clerk doesn't hold up across our mixed stack. Both use standard OIDC — switching is a config change, not a rewrite.

- **Internal team:** Microsoft SSO. Zero change either way.
- **Clients:** Email/password, magic link, or federated SSO via their own IdP.
- **Cost:** $0–25/mo (Clerk) vs $150/mo (Auth0 fallback).
- **Timeline:** 2-week spike → go/no-go → 8 more weeks to full rollout.

---

## Problem

Apps are coupled to Microsoft Entra ID. Clients without Microsoft accounts can't log in. No unified auth layer for internal vs. external users. Building auth per-app is a maintenance tax we don't want.

---

## Constraints

- **6–12 client orgs** onboarding in year one (~60–120 MAU).
- **Mixed stack** (Next.js, Express, Python, etc.) — must stay that way.
- **Cost-conscious**, no hard ceiling.
- **SOC 2 readiness** is a smart default for financial services.

---

## Why Clerk First

|  | Clerk | Auth0 (Fallback) |
| --- | --- | --- |
| **Cost (year 1)** | $0–25/mo | $150/mo |
| **Pricing model** | Linear ($0.02/MAU after 50k) | Cliffs ($150 → $800 → $30k+/yr) |
| **Free tier** | 50k MAU | 500 MAU (B2B) |
| **Official SDKs** | Next.js, React, Express, Python, Go, Java, C#, Ruby/Rails, Vue, Nuxt, Astro, iOS, Android + community SDKs for Angular, Svelte, PHP, Rust, Hono | 30+ SDKs: React, Next.js, Angular, Vue, Express, Django, Flask, Spring Boot, Laravel, .NET, PHP, Swift, Kotlin, Go, Ruby + more |
| **React/Next.js DX** | Drop-in `<SignIn />` components | Redirect to Universal Login |
| **Non-React DX** | Official SDKs for Express, Python, Go, Java, Ruby, C# | Official SDKs for everything + standard OIDC |
| **Enterprise SSO** | Metered on Pro | 10 included on Essentials |
| **Multi-tenant orgs** | ✅ | ✅ |
| **Microsoft SSO** | ✅ | ✅ |
| **SOC 2 Type II** | All tiers | All tiers |
| **HIPAA** | Business ($250/mo) | BAA available |
| **Maturity** | ~4 years, growing fast | 10+ years, Okta-backed |
| **Lock-in risk** | Medium (SDK in React apps) | Low (standard OIDC only) |

**The bet:** Clerk is 6x cheaper with better React DX. They also now have official SDKs for Express, Python, Go, Java, Ruby, and C# — so mixed stack support is broader than expected. Auth0 still has the deepest coverage (30+ SDKs, 10+ years of battle-testing), which is why it's the fallback. The spike validates whether Clerk's newer SDKs are mature enough for our needs.

---

## Why Not the Others

- **Kinde:** Youngest platform (~2022). SDK coverage is actually solid (TypeScript, Python/Flask/FastAPI, Express, Next.js, .NET, Go, Ruby — 22+ frameworks). But: enterprise SSO gated to Pro ($75/mo), bundled billing/feature flags add complexity we don't need, and smallest community for troubleshooting edge cases. Worth revisiting as it matures.
- **Entra External ID:** Deepens MS lock-in. Still maturing. Known federation limitations.
- **Keycloak:** Self-hosted = we own security, patching, uptime. Don't have the headcount.
- **FusionAuth:** Strong Plan C. Long-term escape hatch from Auth0 if pricing gets ugly.

---

## Architecture

```
┌─────────────────┬─────────────────┐
│ Internal Team   │ External Clients │
│ (Microsoft SSO) │ (Email/IdP/SSO)  │
└────────┬────────┴────────┬────────┘
         │                 │
      ┌──┴─────────────────┴──┐
      │  CLERK (or Auth0)     │
      │  OIDC + JWT           │
      └───────────┬───────────┘
                  │
      ┌───────────┴───────────┐
      │  Our Apps             │
      │  React → Clerk SDK    │
      │  Other → Clerk SDK    │
      │    or std OIDC        │
      └───────────────────────┘
```

JWT includes `role`, `org_id`, `permissions`. Apps never talk to the identity provider directly.

---

## Spike: Validate Clerk (Week 1–2)

Not committing yet — testing.

**Setup:** Create Clerk app (free tier). Configure Microsoft SSO, email/password, magic link, MFA.

**Test 1 — React app:** Install `@clerk/nextjs`, drop in `<SignIn />` + `<UserButton />`. Does internal SSO and client login work?

**Test 2 — Non-React app:** Use Clerk's official SDK for that framework (Express, Python, etc.). If no SDK fits, fall back to standard OIDC via the framework's native library. Is the DX acceptable? Any gaps vs. Auth0?

**Test 3 — Enterprise SSO:** Create an Organization, set up a test SAML/OIDC connection. Does federation work? What's the per-connection cost?

**Go/No-Go:**

- ✅ All pass → Proceed with Clerk.
- ❌ Test 2 or 3 fails → Pivot to Auth0. Reuse all OIDC patterns from the spike.

---

## Rollout (Week 3–10)

*Provider below = Clerk or Auth0, depending on spike outcome. Timeline is the same.*

**Week 3–4: Production Setup**

- Upgrade to paid tier if needed. Configure production environment, branding, MFA, custom domain.
- Document auth patterns: Clerk SDK per framework, standard OIDC as fallback for unsupported frameworks.

**Week 5–6: Pilot App**

- Migrate one internal app from Entra direct to the new provider.
- Create a test client Organization. Validate internal + client login with correct role scoping.

**Week 7–9: Rollout**

- Migrate remaining apps one by one.
- Onboard client orgs: create Organization, set up Enterprise Connection if they bring their own IdP.
- Document the client onboarding playbook.

**Week 10: Hardening**

- Bot detection, brute-force protection, webhook integrations.
- Alerts for auth failures and plan limits. Incident response runbook.

---

## What Changes

| Component | Before | After |
| --- | --- | --- |
| Auth provider | Entra ID (direct) | Clerk or Auth0 (brokers to Entra) |
| Login UX (React) | Redirect to Microsoft | Embedded component (Clerk) or redirect (Auth0) |
| Login UX (Other) | Redirect to Microsoft | Redirect to hosted login page |
| Client login | Not supported | Email/pass, magic link, federated SSO |
| Token issuer | Entra ID | Clerk or Auth0 |
| Internal user experience | "Sign in with Microsoft" | "Sign in with Microsoft" (same) |

---

## Pricing at Scale

| Provider | 250 MAU | 550 MAU | 1,050 MAU |
| --- | --- | --- | --- |
| **Clerk Free** | $0 | $0 | $0 |
| **Clerk Pro** | $25 | $25 | $25 |
| **Clerk Pro + SSO metering** | ~$25–75 | ~$50–100 | ~$50–125 |
| **Auth0 Essentials** | $150 | $150–300 | Enterprise (custom) |
| **Auth0 Professional** | $800 | $800 | $800 |

All under 50k MAU, so Clerk's free tier covers year one entirely. Enterprise SSO metering is the one wildcard — validated during spike.

---

## Next Steps

1. **Approve the strategy.** Cheaper option first, safety net defined.
2. **Create Clerk app.** Free tier. 5 minutes.
3. **Spike (2 days).** React app + non-React app + Enterprise SSO. Go/no-go gate.
4. **Pick pilot app.** Which internal app becomes client-facing first?
5. **Execute rollout.** 8 weeks post-spike.

---

> **Nothing we build during the spike is throwaway. The spike tells us which path. Either way, we ship in 10 weeks.**
