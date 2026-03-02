/**
 * ClerkUserButton LiveView hook.
 *
 * Mounts Clerk's UserButton component (profile pic + dropdown menu)
 * into the hook element. Equivalent to <UserButton /> in React.
 */
const ClerkUserButton = {
  mounted() {
    this.mountButton()
  },

  async mountButton() {
    if (typeof window.Clerk === "undefined") {
      setTimeout(() => this.mountButton(), 100)
      return
    }

    await window.Clerk.load()

    if (window.Clerk.user) {
      window.Clerk.mountUserButton(this.el, {
        afterSignOutUrl: "/sign-out",
      })
    }
  },

  destroyed() {
    if (typeof window.Clerk !== "undefined") {
      window.Clerk.unmountUserButton(this.el)
    }
  },
}

export default ClerkUserButton
