/**
 * ClerkSignOut LiveView hook.
 *
 * Calls Clerk.signOut() which clears the __session cookie,
 * then redirects to /sign-out which clears the Phoenix session.
 * Both cookies must be cleared for a full sign-out.
 */
const ClerkSignOut = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      e.preventDefault()
      this.signOut()
    })
  },

  async signOut() {
    if (typeof window.Clerk !== "undefined") {
      await window.Clerk.load()
      await window.Clerk.signOut()
    } else {
      document.cookie = "__session=; Max-Age=0; path=/"
    }

    // Redirect to server-side route that clears Phoenix session
    window.location.href = "/sign-out"
  },
}

export default ClerkSignOut
