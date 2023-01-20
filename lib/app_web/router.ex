defmodule AppWeb.Router do
  use AppWeb, :router

  import AppWeb.Plugs.Session

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {AppWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_session_uid
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_session_uid
  end

  scope "/", AppWeb do
    pipe_through :browser

    live "/", Live.Index
  end

  scope "/api", AppWeb do
    pipe_through :api

    get "/me", Controllers.Customer, :me

    get "/cart", Controllers.Cart, :index
    post "/cart/add_product", Controllers.Cart, :add_product

    get "/products", Controllers.Product, :index
    post "/products/create", Controllers.Product, :create
  end

  # Other scopes may use custom stacks.
  # scope "/api", AppWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard",
        metrics: AppWeb.Telemetry,
        ecto_repos: [App.Repo]
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
