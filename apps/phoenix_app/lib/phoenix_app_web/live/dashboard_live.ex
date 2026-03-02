defmodule PhoenixAppWeb.DashboardLive do
  use PhoenixAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto mt-8">
      <h1 class="text-2xl font-bold mb-6">Dashboard</h1>

      <div class="bg-gray-800 border border-gray-700 rounded-lg p-6 mb-6">
        <h2 class="text-lg font-semibold mb-4">Authenticated User</h2>
        <dl class="space-y-2">
          <div class="flex gap-2">
            <dt class="font-medium text-green-600">Clerk ID:</dt>
            <dd class="font-mono text-sm"><%= @current_user.clerk_id %></dd>
          </div>
          <div class="flex gap-2">
            <dt class="font-medium text-green-600">Email:</dt>
            <dd><%= @current_user.email %></dd>
          </div>
          <div class="flex gap-2">
            <dt class="font-medium text-green-600">Org ID:</dt>
            <dd class="font-mono text-sm"><%= @current_user.org_id || "None" %></dd>
          </div>
          <div class="flex gap-2">
            <dt class="font-medium text-green-600">Org Role:</dt>
            <dd><%= @current_user.org_role || "None" %></dd>
          </div>
          <div class="flex gap-2">
            <dt class="font-medium text-green-600">Org Slug:</dt>
            <dd class="font-mono text-sm"><%= @current_user[:org_slug] || "None" %></dd>
          </div>
        </dl>
      </div>

      <div class="mt-6">
        <button
          id="clerk-sign-out"
          phx-hook="ClerkSignOut"
          class="bg-red-600 text-white px-4 py-2 rounded hover:bg-red-700"
        >
          Sign Out
        </button>
      </div>

      <div class="text-sm text-green-700 mt-6">
        <p>Auth flow: ClerkJS → __session cookie → ClerkAuthPlug → Phoenix session → LiveView on_mount</p>
      </div>
    </div>
    """
  end
end
