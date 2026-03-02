defmodule PhoenixAppWeb.LiveAuthTest do
  use PhoenixAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "require_authenticated_user" do
    test "redirects to /sign-in when no session user", %{conn: conn} do
      conn = init_test_session(conn, %{})
      assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, "/dashboard")
    end

    test "allows access when session has current_user", %{conn: conn} do
      user = %{
        "clerk_id" => "user_test123",
        "email" => "test@example.com",
        "org_id" => nil,
        "org_role" => nil
      }

      conn = init_test_session(conn, %{"current_user" => user})
      {:ok, _lv, html} = live(conn, "/dashboard")
      assert html =~ "user_test123"
      assert html =~ "test@example.com"
    end
  end

  describe "maybe_authenticated" do
    test "assigns nil when no session user", %{conn: conn} do
      conn = init_test_session(conn, %{})
      {:ok, _lv, html} = live(conn, "/")
      # Home page should render without error
      assert html =~ "Clerk Auth Spike"
    end

    test "assigns user when session has current_user", %{conn: conn} do
      user = %{
        "clerk_id" => "user_test123",
        "email" => "test@example.com",
        "org_id" => nil,
        "org_role" => nil
      }

      conn = init_test_session(conn, %{"current_user" => user})
      {:ok, _lv, html} = live(conn, "/")
      assert html =~ "Clerk Auth Spike"
    end
  end
end
