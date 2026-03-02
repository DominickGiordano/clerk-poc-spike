defmodule PhoenixAppWeb.Plugs.AshActorPlugTest do
  use PhoenixAppWeb.ConnCase, async: false

  alias PhoenixAppWeb.Plugs.AshActorPlug

  describe "call/2" do
    test "upserts user and sets Ash actor when current_user is present" do
      conn =
        build_conn()
        |> init_test_session(%{})
        |> Plug.Conn.assign(:current_user, %{
          clerk_id: "user_plug_test_001",
          email: "plug_test@example.com",
          org_id: "org_plug",
          org_role: "admin"
        })
        |> AshActorPlug.call(%{})

      assert conn.assigns.ash_user
      assert conn.assigns.ash_user.clerk_id == "user_plug_test_001"
      assert conn.assigns.ash_user.email == "plug_test@example.com"

      # Verify Ash actor was set
      actor = Ash.PlugHelpers.get_actor(conn)
      assert actor.id == conn.assigns.ash_user.id
    end

    test "does nothing when current_user is nil" do
      conn =
        build_conn()
        |> init_test_session(%{})
        |> Plug.Conn.assign(:current_user, nil)
        |> AshActorPlug.call(%{})

      refute Map.has_key?(conn.assigns, :ash_user)
    end
  end
end
