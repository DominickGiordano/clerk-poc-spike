defmodule PhoenixAppWeb.Plugs.ClerkAuthPlug do
  @moduledoc """
  Verifies Clerk-issued JWTs from the `__session` cookie or `Authorization: Bearer` header.

  On success, assigns `current_user` map to conn and stores it in the session
  so LiveView can read it via `on_mount`.

  Behavior:
  - Token found + valid → update session and assigns with user
  - Token found + invalid → clear session and assigns (sign-out / expired)
  - No token found → read existing session into assigns (preserves LiveView session bridge)

  Uses runtime config — never compile-time module attributes for env vars.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn = fetch_cookies(conn)

    case extract_token(conn) do
      nil ->
        # No JWT present — preserve existing session (may have been set by a prior request)
        existing = get_session(conn, :current_user)
        assign(conn, :current_user, atomize_keys(existing))

      token ->
        case verify_token(token) do
          {:ok, claims} ->
            user = %{
              clerk_id: claims["sub"],
              email: claims["email"],
              org_id: claims["org_id"],
              org_role: claims["org_role"]
            }

            conn
            |> assign(:current_user, user)
            |> put_session(:current_user, user)

          {:error, _reason} ->
            conn
            |> assign(:current_user, nil)
            |> put_session(:current_user, nil)
        end
    end
  end

  defp extract_token(conn) do
    case conn.cookies["__session"] do
      token when is_binary(token) and token != "" ->
        token

      _ ->
        case get_req_header(conn, "authorization") do
          ["Bearer " <> token] -> token
          _ -> nil
        end
    end
  end

  defp verify_token(token) do
    pem = clerk_jwt_key()

    if is_nil(pem) or pem == "" do
      {:error, :no_jwt_key_configured}
    else
      signer = Joken.Signer.create("RS256", %{"pem" => pem})

      case Joken.verify(token, signer) do
        {:ok, claims} ->
          now = System.system_time(:second)

          cond do
            is_integer(claims["exp"]) and claims["exp"] < now ->
              {:error, :token_expired}

            is_integer(claims["nbf"]) and claims["nbf"] > now ->
              {:error, :token_not_yet_valid}

            true ->
              {:ok, claims}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  # Session data may come back with string keys after serialization
  defp atomize_keys(nil), do: nil

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) -> {String.to_existing_atom(k), v}
      {k, v} when is_atom(k) -> {k, v}
    end)
  end

  defp clerk_jwt_key do
    Application.get_env(:phoenix_app, :clerk)[:jwt_key]
  end
end
