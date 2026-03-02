defmodule PhoenixAppWeb.SignInLive do
  use PhoenixAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto mt-8">
      <h1 class="text-2xl font-bold mb-6 text-center">Sign In</h1>
      <div id="clerk-sign-in" phx-hook="ClerkSignIn" phx-update="ignore" class="flex justify-center">
        <p class="text-gray-500">Loading sign-in...</p>
      </div>
    </div>
    """
  end
end
