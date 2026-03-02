# Clerk Auth Spike — Elixir / LiveView / Ash Stack

> **Author:** Dominick  
> **Date:** March 2026  
> **Status:** Pre-spike planning doc  
> **Goal:** Validate Clerk as the auth broker for a mixed-stack environment, starting with Elixir/Phoenix/LiveView/Ash — our most complex integration.

---

## Context

### Where We Are Today

Most internal apps use **OAuth via Microsoft Entra ID**. It works well for the team — we get SSO, no password management, and it's invisible to users. No plans to change that for internal users.

The problem: once we start exposing these apps to **external clients**, Entra ID falls apart. Clients don't have Microsoft accounts. We need a flexible auth layer that:

- Still lets our team sign in with Microsoft (no change to their experience)
- Gives external clients email/password, magic link, or their own federated SSO
- Works across a **mixed stack** — Elixir/Phoenix, Next.js, Express, Python, and more

### Why Clerk (and Why We're Spiking First)

Clerk was chosen as the primary candidate because it's significantly cheaper than Auth0 and has strong React/Next.js DX. However, **Clerk does not have an official Elixir SDK.** That's the gap this spike is validating.

Auth0 is the defined fallback. Both use standard OIDC, so switching is a config change, not a rewrite.

---

## The Honest Elixir Reality

### No Official SDK

Unlike Next.js, Express, or Python — Clerk does **not** maintain an official Elixir SDK.

What exists in the ecosystem:
- [`clerk_elixir`](https://github.com/nathanjohnson320/clerk_elixir) — community-built Hex package, not Clerk-maintained. Provides a thin REST API wrapper and a `Clerk.AuthenticationPlug`.
- Standard Elixir JWT libraries (`Joken`, `JOSE`) — used to manually verify Clerk-issued JWTs.

**Bottom line:** The Elixir integration is a DIY job. Clerk handles auth on the frontend via ClerkJS. Phoenix handles JWT verification on the backend. This is workable, but it's more plumbing than the proposal doc implied.

### LiveView Cookie Problem

LiveView runs over **WebSockets**, not HTTP. This creates a specific auth challenge:

- Clerk sets a `__session` cookie (JWT) after login via the standard HTTP flow
- LiveView can't read or set cookies directly — it only has access to what was in the session at mount time
- You can't set cookies from inside a LiveView

**The workaround that works:**

```
User signs in via Clerk JS (frontend)
  → Clerk issues __session JWT cookie
  → Phoenix Plug intercepts HTTP request, verifies JWT via Joken
  → Verified user stored in Phoenix session (server-side)
  → LiveView reads current_user from session via on_mount hook
```

This pattern is well-understood in the Phoenix community. It's not Clerk-specific — it's the same approach used with Auth0, Google OAuth, etc.

### Ash Authentication Risk

`AshAuthentication` is designed to **own** the auth lifecycle — sign up, sign in, token management, all of it. Plugging Clerk in as an external IdP means you're bypassing most of that.

The realistic usage if you go Clerk + Ash:
- Use **Ash** for user record management (storing users, roles, org membership in your DB)
- Use **Clerk** for the actual auth handshake (issuing JWTs, managing sessions, SSO federation)
- Skip `AshAuthentication`'s built-in strategies and just verify the externally-issued JWT

This may be totally fine depending on how deep Ash auth is embedded in your apps. **This is the critical unknown that Day 2 of the spike answers.**

---

## Spike Plan

### Goal

Validate that Clerk JWT verification works cleanly in Phoenix/LiveView and that the Ash story is viable — before committing to anything.

**Duration:** 2 days  
**Environment:** Fresh Phoenix app on Clerk free tier

---

### Day 1 — Core Auth Flow

**Objective:** Clerk issues JWTs → Phoenix verifies them → internal Microsoft SSO works

#### Step 1: Clerk Setup (~30 min)

1. Create Clerk account at [clerk.com](https://clerk.com) (free tier)
2. Create a new application
3. Enable **Microsoft** as a social provider (OAuth → Microsoft)
4. Enable **Email/Password** and **Magic Link** for future client use
5. Grab from the Clerk dashboard:
   - `CLERK_SECRET_KEY`
   - `CLERK_PUBLISHABLE_KEY`
   - JWT Public Key (PEM format) — found under **API Keys → Show JWT Public Key**

#### Step 2: Phoenix App Setup

Add dependencies to `mix.exs`:

```elixir
{:joken, "~> 2.6"},
{:jose, "~> 1.11"},
{:req, "~> 0.5"}   # for Clerk REST API calls if needed
```

Set env vars:

```bash
export CLERK_SECRET_KEY="sk_test_..."
export CLERK_PUBLISHABLE_KEY="pk_test_..."
export CLERK_JWT_KEY="-----BEGIN PUBLIC KEY-----\n..."
```

#### Step 3: Build the ClerkAuthPlug

Create `lib/my_app_web/plugs/clerk_auth_plug.ex`:

```elixir
defmodule MyAppWeb.ClerkAuthPlug do
  import Plug.Conn

  # BUG: This runs at compile time, not runtime. See FINDINGS.md.
  # Fix: Use Application.get_env(:my_app, :clerk)[:jwt_key] in runtime.exs
  @clerk_jwt_key System.get_env("CLERK_JWT_KEY")

  def init(opts), do: opts

  def call(conn, _opts) do
    with token when not is_nil(token) <- get_token(conn),
         {:ok, claims} <- verify_token(token) do
      assign(conn, :current_user, %{
        id: claims["sub"],
        email: claims["email"],
        org_id: claims["org_id"]
      })
    else
      _ -> assign(conn, :current_user, nil)
    end
  end

  defp get_token(conn) do
    # Clerk sets the JWT in the __session cookie
    conn = fetch_cookies(conn)
    conn.cookies["__session"] ||
      get_req_header(conn, "authorization")
      |> List.first()
      |> case do
        "Bearer " <> token -> token
        _ -> nil
      end
  end

  defp verify_token(token) do
    signer = Joken.Signer.create("RS256", %{"pem" => @clerk_jwt_key})
    Joken.verify(token, signer)
  end
end
```

Wire it into your router pipeline:

```elixir
pipeline :browser do
  plug :accepts, ["html"]
  plug :fetch_session
  plug :fetch_live_flash
  plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
  plug :protect_from_forgery
  plug :put_secure_browser_headers
  plug MyAppWeb.ClerkAuthPlug   # <-- add here
end
```

#### Step 4: Add ClerkJS to the Frontend

In `root.html.heex`, add before `</head>`:

```html
<script
  async
  crossorigin="anonymous"
  data-clerk-publishable-key={System.get_env("CLERK_PUBLISHABLE_KEY")}
  src="https://[your-clerk-frontend-api].clerk.accounts.dev/npm/@clerk/clerk-js@latest/dist/clerk.browser.js"
  type="text/javascript"
></script>

<script>
  window.addEventListener("load", async function () {
    await Clerk.load();
    if (Clerk.user) {
      // User is signed in
    } else {
      // Show sign in UI
      const signInDiv = document.getElementById("sign-in");
      if (signInDiv) Clerk.mountSignIn(signInDiv);
    }
  });
</script>
```

Add a sign-in mount target wherever you want the login UI:

```html
<div id="sign-in"></div>
```

#### Day 1 Test Criteria

- [ ] Internal user clicks "Sign in with Microsoft" → redirected through Clerk → lands back in Phoenix app
- [ ] `conn.assigns.current_user` is populated with correct user data
- [ ] `__session` cookie is present and verifiable
- [ ] Non-authenticated request correctly gets `current_user: nil`

---

### Day 2 — LiveView + Ash

**Objective:** Bridge verified auth into LiveView sessions and assess Ash compatibility

#### Step 5: on_mount Hook for LiveView

Create `lib/my_app_web/live/live_auth.ex`:

```elixir
defmodule MyAppWeb.LiveAuth do
  import Phoenix.LiveView

  def on_mount(:require_authenticated_user, _params, session, socket) do
    case session["current_user"] do
      nil ->
        socket =
          socket
          |> put_flash(:error, "You must be logged in.")
          |> redirect(to: "/sign-in")
        {:halt, socket}

      user ->
        {:cont, assign(socket, :current_user, user)}
    end
  end

  def on_mount(:maybe_authenticated, _params, session, socket) do
    {:cont, assign(socket, :current_user, session["current_user"])}
  end
end
```

You need to store the user in the session during the HTTP phase (before LiveView mounts). Update your plug to also write to session:

```elixir
# In ClerkAuthPlug.call/2, after verifying token:
conn
|> assign(:current_user, user)
|> put_session(:current_user, user)
```

Wire `on_mount` in your router:

```elixir
live_session :authenticated,
  on_mount: [{MyAppWeb.LiveAuth, :require_authenticated_user}] do
  live "/dashboard", DashboardLive, :index
  live "/reports", ReportsLive, :index
end
```

#### Step 6: Ash Authentication Assessment

Run through these questions manually:

1. **How deep is AshAuthentication in your app?**
   - If it's just handling sign-up/sign-in UI → safe to bypass, use Clerk for that
   - If it's managing tokens, policies, or actor resolution → more work to untangle

2. **Can you configure AshAuthentication to accept an external actor?**
   - Yes — you can set the actor on the Ash context manually from `conn.assigns.current_user`
   - `Ash.set_actor(user)` in your plugs/LiveView hooks

3. **Does your Ash resource authorization rely on AshAuthentication's built-in token strategies?**
   - If yes → you'll need to map Clerk's JWT claims to your Ash user records
   - Means: on each request, look up or upsert a local User record by Clerk's `sub` (user ID)

#### Day 2 Test Criteria

- [ ] LiveView `on_mount` correctly inherits authenticated user from HTTP session
- [ ] Unauthenticated users are redirected before LiveView mounts
- [ ] Ash actor can be set from Clerk-verified user without breaking policy evaluation
- [ ] External client user (email/password) flows through the same path as internal Microsoft SSO user

---

## Go / No-Go Decision

After the 2-day spike, evaluate:

| Test | Pass | Fail → Action |
|---|---|---|
| Microsoft SSO via Clerk works | ✅ proceed | 🔴 stop, check Clerk Microsoft config |
| JWT verification in Phoenix plug | ✅ proceed | 🔴 debug Joken / key format issues |
| LiveView session bridge works | ✅ proceed | 🟡 solvable, add a day |
| Ash actor resolution works | ✅ proceed | 🟡 add Clerk→local user sync layer |
| Ash auth is too tightly coupled to bypass | — | 🔴 pivot Elixir apps to Auth0 + ueberauth |

**If Ash is the blocker:** Pivot the Elixir stack to Auth0 with [`ueberauth`](https://github.com/ueberauth/ueberauth) + [`ueberauth_auth0`](https://github.com/ueberauth/ueberauth_auth0). This is the well-worn path for Elixir + external auth. React/Next.js apps still use Clerk. Both stacks use OIDC. No rewrite required.

---

## What Doesn't Change

Regardless of Clerk vs Auth0 outcome:

- **Internal users** still sign in with Microsoft. That experience is unchanged.
- **JWT structure** (`role`, `org_id`, `permissions`) is the same either way — apps read from claims.
- **Apps never talk to the IdP directly** — they only verify tokens.
- **OIDC patterns** built during the spike are reusable on either provider.

---

## Open Questions for Later

These don't block the spike but need answers before full rollout:

- How do we handle Clerk → local DB user sync? (Webhooks? On-demand upsert?)
- What's the org onboarding flow for enterprise clients bringing their own IdP (SAML/OIDC)?
- Do we need per-org role scoping or is global role enough for year one?
- Ash policy evaluation — do policies need to be rewritten to read from Clerk JWT claims vs. local user attributes?

---

## References

- [clerk_elixir (community SDK)](https://github.com/nathanjohnson320/clerk_elixir)
- [Clerk JWT Manual Verification Docs](https://clerk.com/docs/guides/sessions/manual-jwt-verification)
- [Joken — Elixir JWT library](https://hexdocs.pm/joken)
- [Phoenix LiveView Authentication Pattern](https://elixircasts.io/phoenix-liveview-authentication)
- [AshAuthentication Docs](https://hexdocs.pm/ash_authentication)
- [ueberauth_auth0 (fallback path)](https://github.com/ueberauth/ueberauth_auth0)

---

## Spike Outcomes (Post-Implementation)

> Added after building the POC apps. See `docs/FINDINGS.md` for full analysis.

### Day 1 Test Criteria — Results

- [x] ~~Internal user clicks "Sign in with Microsoft"~~ → **Structural pass.** ClerkJS sign-in component mounts, JWT flow validated with test keys. Live Clerk instance needed for Microsoft SSO.
- [x] `conn.assigns.current_user` is populated with correct user data → **Pass.** 8 unit tests confirm all cases.
- [x] `__session` cookie is present and verifiable → **Pass.** Cookie and Bearer header extraction both tested.
- [x] Non-authenticated request correctly gets `current_user: nil` → **Pass.**

### Day 2 Test Criteria — Results

- [x] LiveView `on_mount` correctly inherits authenticated user from HTTP session → **Pass.** 4 test cases.
- [x] Unauthenticated users are redirected before LiveView mounts → **Pass.**
- [x] Ash actor can be set from Clerk-verified user without breaking policy evaluation → **Pass.** `Ash.PlugHelpers.set_actor/2` works with plain Ash resource.
- [x] ~~External client user (email/password) flows through the same path as internal Microsoft SSO user~~ → **Pass by design.** Both produce identical JWTs → same plug → same session.

### Bugs Found in Original Plan

1. **Compile-time env var bug (Step 3):** `@clerk_jwt_key System.get_env("CLERK_JWT_KEY")` runs at compile time, not runtime. Fixed with `Application.get_env(:phoenix_app, :clerk)[:jwt_key]` in `runtime.exs`.
2. **Session clearing bug:** Original plug cleared session when no JWT present, breaking LiveView reconnections. Fixed: no-token case now preserves existing session.
3. **Repo module conflict:** `use Ecto.Repo` and `use AshPostgres.Repo` can't be combined (duplicate `start_link/1`). Must use only `AshPostgres.Repo` which wraps `Ecto.Repo`.

### Answered Open Questions

- **Clerk → local DB user sync:** On-demand upsert in `AshActorPlug` (upsert by `clerk_id` on each request). Simple, no webhook infrastructure needed.
- **Ash policy evaluation:** Policies work as-is. `actor(:id)` reads from the Ash resource set via `set_actor/2`. No AshAuthentication dependency.

### Remaining Open Questions

- Org onboarding flow for enterprise clients with own IdP
- Per-org role scoping vs global roles
- Session duration and refresh strategy
- Custom JWT template for email claim (verify with live Clerk instance)
