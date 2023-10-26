defmodule DisplayGeodataApiWeb.Router do
  use DisplayGeodataApiWeb, :router
  alias DisplayGeodataApi.Tokens.TokenAuth

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {DisplayGeodataApiWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)

    # # Tell Plug to match the incoming request with the defined endpoints
    # plug(:match)
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(TokenAuth)
    plug(DisplayGeodataApi.RateLimiter) # Ajoutez cette ligne
  end

  # scope "/", DisplayGeodataApiWeb do
  #   pipe_through(:browser)

  #   get("/", PageController, :home)
  # end

  scope "/", DisplayGeodataApi do
    pipe_through(:api)

    get("/", CarreauxController, :search_optimized)
    get("/carreaux/search", CarreauxController, :search_optimized)
    # get("/temp", CarreauxController, :temp)
  end

  # Other scopes may use custom stacks.
  # scope "/api", DisplayGeodataApiWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:display_geodata_api, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: DisplayGeodataApiWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
