defmodule PhoenixAppWeb.Plugs.AshActorPlug do
  @moduledoc """
  Runs after ClerkAuthPlug. Takes Clerk claims from conn.assigns.current_user,
  upserts a local Ash User record, and sets it as the Ash actor.

  Key spike question: Does `Ash.PlugHelpers.set_actor/2` work with a plain
  Ash resource not managed by AshAuthentication?
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(%{assigns: %{current_user: nil}} = conn, _opts), do: conn

  def call(%{assigns: %{current_user: clerk_user}} = conn, _opts) do
    case upsert_user(clerk_user) do
      {:ok, user} ->
        conn
        |> assign(:ash_user, user)
        |> Ash.PlugHelpers.set_actor(user)

      {:error, _reason} ->
        conn
    end
  end

  def call(conn, _opts), do: conn

  defp upsert_user(clerk_user) do
    PhoenixApp.Accounts.User
    |> Ash.Changeset.for_create(:upsert_from_clerk, %{
      clerk_id: clerk_user.clerk_id,
      email: clerk_user.email || "unknown@example.com",
      org_id: clerk_user.org_id,
      display_name: clerk_user.email
    })
    |> Ash.create(authorize?: false)
  end
end
