defmodule PhoenixAppWeb.HomeLive do
  use PhoenixAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto mt-8">
      <h1 class="text-2xl font-bold mb-4">Clerk Auth Spike</h1>

      <%= if @current_user do %>
        <p class="mb-4">Welcome back, <%= @current_user.email %>.</p>
        <.link href="/dashboard" class="text-green-300 underline">Go to Dashboard</.link>
      <% else %>
        <p class="mb-4">Sign in to access the dashboard.</p>
        <.link href="/sign-in" class="text-green-300 underline">Sign In</.link>
      <% end %>
    </div>
    """
  end
end
