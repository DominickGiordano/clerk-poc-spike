defmodule PhoenixAppWeb.VerifyController do
  use PhoenixAppWeb, :controller

  def show(conn, _params) do
    case conn.assigns[:current_user] do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid or missing token"})

      user ->
        json(conn, %{
          verified: true,
          clerk_id: user.clerk_id,
          email: user.email,
          org_id: user.org_id,
          org_role: user.org_role
        })
    end
  end
end
