defmodule PhoenixAppWeb.PageControllerTest do
  use PhoenixAppWeb.ConnCase

  test "GET / renders home page", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Clerk Auth Spike"
  end
end
