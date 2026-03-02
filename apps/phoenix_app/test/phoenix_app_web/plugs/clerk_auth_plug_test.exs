defmodule PhoenixAppWeb.Plugs.ClerkAuthPlugTest do
  use PhoenixAppWeb.ConnCase, async: true

  alias PhoenixAppWeb.Plugs.ClerkAuthPlug

  import PhoenixAppWeb.JwtHelpers

  setup do
    {private_key, public_pem} = generate_rsa_key_pair()
    {wrong_private_key, _wrong_public_pem} = generate_rsa_key_pair()

    # Configure the app to use our test public key
    original_config = Application.get_env(:phoenix_app, :clerk)
    Application.put_env(:phoenix_app, :clerk, Keyword.merge(original_config || [], jwt_key: public_pem))

    on_exit(fn ->
      if original_config do
        Application.put_env(:phoenix_app, :clerk, original_config)
      else
        Application.delete_env(:phoenix_app, :clerk)
      end
    end)

    %{private_key: private_key, wrong_private_key: wrong_private_key, public_pem: public_pem}
  end

  describe "valid token via cookie" do
    test "assigns current_user from __session cookie", %{private_key: private_key} do
      claims = valid_claims()
      token = sign_jwt(claims, private_key)

      conn =
        build_conn()
        |> init_test_session(%{})
        |> put_req_cookie("__session", token)
        |> ClerkAuthPlug.call(%{})

      assert conn.assigns.current_user == %{
               clerk_id: "user_test123",
               email: "test@example.com",
               org_id: nil,
               org_role: nil,
               org_slug: nil
             }
    end
  end

  describe "valid token via Bearer header" do
    test "assigns current_user from Authorization header", %{private_key: private_key} do
      claims = valid_claims()
      token = sign_jwt(claims, private_key)

      conn =
        build_conn()
        |> init_test_session(%{})
        |> put_req_header("authorization", "Bearer #{token}")
        |> ClerkAuthPlug.call(%{})

      assert conn.assigns.current_user == %{
               clerk_id: "user_test123",
               email: "test@example.com",
               org_id: nil,
               org_role: nil,
               org_slug: nil
             }
    end
  end

  describe "expired token" do
    test "assigns nil for expired token", %{private_key: private_key} do
      claims = valid_claims(%{"exp" => System.system_time(:second) - 100})
      token = sign_jwt(claims, private_key)

      conn =
        build_conn()
        |> init_test_session(%{})
        |> put_req_cookie("__session", token)
        |> ClerkAuthPlug.call(%{})

      assert conn.assigns.current_user == nil
    end
  end

  describe "future nbf" do
    test "assigns nil for token not yet valid", %{private_key: private_key} do
      claims = valid_claims(%{"nbf" => System.system_time(:second) + 3600})
      token = sign_jwt(claims, private_key)

      conn =
        build_conn()
        |> init_test_session(%{})
        |> put_req_cookie("__session", token)
        |> ClerkAuthPlug.call(%{})

      assert conn.assigns.current_user == nil
    end
  end

  describe "wrong signing key" do
    test "assigns nil for token signed with wrong key", %{wrong_private_key: wrong_private_key} do
      claims = valid_claims()
      token = sign_jwt(claims, wrong_private_key)

      conn =
        build_conn()
        |> init_test_session(%{})
        |> put_req_cookie("__session", token)
        |> ClerkAuthPlug.call(%{})

      assert conn.assigns.current_user == nil
    end
  end

  describe "malformed token" do
    test "assigns nil for malformed token" do
      conn =
        build_conn()
        |> init_test_session(%{})
        |> put_req_cookie("__session", "not.a.valid.jwt")
        |> ClerkAuthPlug.call(%{})

      assert conn.assigns.current_user == nil
    end
  end

  describe "no token" do
    test "assigns nil when no token and no session" do
      conn =
        build_conn()
        |> init_test_session(%{})
        |> ClerkAuthPlug.call(%{})

      assert conn.assigns.current_user == nil
    end
  end

  describe "token with org claims (Clerk v2 format)" do
    test "populates org fields from nested 'o' claim", %{private_key: private_key} do
      claims =
        valid_claims(%{
          "o" => %{"id" => "org_abc123", "rol" => "admin", "slg" => "my-org"}
        })

      token = sign_jwt(claims, private_key)

      conn =
        build_conn()
        |> init_test_session(%{})
        |> put_req_cookie("__session", token)
        |> ClerkAuthPlug.call(%{})

      assert conn.assigns.current_user == %{
               clerk_id: "user_test123",
               email: "test@example.com",
               org_id: "org_abc123",
               org_role: "admin",
               org_slug: "my-org"
             }
    end
  end

  describe "token with legacy org claims" do
    test "populates org fields from flat org_id/org_role claims", %{private_key: private_key} do
      claims =
        valid_claims(%{
          "org_id" => "org_abc123",
          "org_role" => "admin"
        })

      token = sign_jwt(claims, private_key)

      conn =
        build_conn()
        |> init_test_session(%{})
        |> put_req_cookie("__session", token)
        |> ClerkAuthPlug.call(%{})

      assert conn.assigns.current_user == %{
               clerk_id: "user_test123",
               email: "test@example.com",
               org_id: "org_abc123",
               org_role: "admin",
               org_slug: nil
             }
    end
  end
end
