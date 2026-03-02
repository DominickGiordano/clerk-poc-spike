defmodule PhoenixAppWeb.LiveAuth do
  @moduledoc """
  LiveView on_mount callbacks for authentication.

  Reads `current_user` from the Phoenix session (set by ClerkAuthPlug during HTTP phase).
  LiveView can't read cookies directly — this session bridge is the standard pattern.
  """
  import Phoenix.LiveView
  import Phoenix.Component, only: [assign: 3]

  def on_mount(:require_authenticated_user, _params, session, socket) do
    case session["current_user"] do
      nil ->
        socket =
          socket
          |> put_flash(:error, "You must be logged in.")
          |> redirect(to: "/sign-in")

        {:halt, socket}

      user ->
        {:cont, assign(socket, :current_user, atomize_keys(user))}
    end
  end

  def on_mount(:maybe_authenticated, _params, session, socket) do
    user = session["current_user"]
    {:cont, assign(socket, :current_user, atomize_keys(user))}
  end

  # Session data may come back with string keys after serialization
  defp atomize_keys(nil), do: nil

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) -> {String.to_existing_atom(k), v}
      {k, v} when is_atom(k) -> {k, v}
    end)
  end
end
