/**
 * ClerkSignIn LiveView hook.
 *
 * Mounts Clerk's sign-in component into the hook element.
 * After successful sign-in, ClerkJS sets the `__session` cookie,
 * then we do a full page redirect (not LiveView push) so the
 * HTTP plug can read the new cookie.
 */
const ClerkSignIn = {
  mounted() {
    this.mountClerk()
  },

  async mountClerk() {
    // Wait for Clerk to be loaded (script tag in root.html.heex)
    if (typeof window.Clerk === "undefined") {
      // Retry after a short delay if Clerk hasn't loaded yet
      setTimeout(() => this.mountClerk(), 100)
      return
    }

    await window.Clerk.load()

    if (window.Clerk.user) {
      // Already signed in — redirect to dashboard
      window.location.href = "/dashboard"
      return
    }

    // Mount the sign-in component
    window.Clerk.mountSignIn(this.el, {
      afterSignInUrl: "/dashboard",
      afterSignUpUrl: "/dashboard",
    })
  },

  destroyed() {
    if (typeof window.Clerk !== "undefined") {
      window.Clerk.unmountSignIn(this.el)
    }
  },
}

export default ClerkSignIn
