defmodule PhoenixAppWeb.SignOutController do
  use PhoenixAppWeb, :controller

  def sign_out(conn, _params) do
    conn
    |> clear_session()
    |> redirect(to: "/")
  end
end
