defmodule PhoenixAppWeb.Router do
  use PhoenixAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PhoenixAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug PhoenixAppWeb.Plugs.ClerkAuthPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug PhoenixAppWeb.Plugs.ClerkAuthPlug
  end

  # Public routes — ClerkJS sign-in page
  scope "/", PhoenixAppWeb do
    pipe_through :browser

    live_session :public, on_mount: [{PhoenixAppWeb.LiveAuth, :maybe_authenticated}] do
      live "/", HomeLive, :index
      live "/sign-in", SignInLive, :index
    end
  end

  # Sign-out route — clears Phoenix session, then redirects
  scope "/", PhoenixAppWeb do
    pipe_through :browser

    get "/sign-out", SignOutController, :sign_out
  end

  # Authenticated routes — require signed-in user
  scope "/", PhoenixAppWeb do
    pipe_through :browser

    live_session :authenticated, on_mount: [{PhoenixAppWeb.LiveAuth, :require_authenticated_user}] do
      live "/dashboard", DashboardLive, :index
    end
  end

  # API routes — cross-app JWT verification
  scope "/api", PhoenixAppWeb do
    pipe_through :api

    get "/verify", VerifyController, :show
  end
end
