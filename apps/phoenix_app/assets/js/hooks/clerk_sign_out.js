/**
 * ClerkSignOut LiveView hook.
 *
 * Calls Clerk.signOut() which clears the __session cookie,
 * then does a full page redirect to "/" so the HTTP plug
 * sees the cleared cookie.
 */
const ClerkSignOut = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      e.preventDefault()
      this.signOut()
    })
  },

  async signOut() {
    if (typeof window.Clerk === "undefined") {
      // Clerk not loaded — just clear cookie and redirect
      document.cookie = "__session=; Max-Age=0; path=/"
      window.location.href = "/"
      return
    }

    await window.Clerk.load()
    await window.Clerk.signOut()
    window.location.href = "/"
  },
}

export default ClerkSignOut
