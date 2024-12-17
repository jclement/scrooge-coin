defmodule ScroogeCoinWeb.Router do
  @moduledoc false
  use ScroogeCoinWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ScroogeCoinWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  def swagger_info do
    %{
      info: %{
        version: "1.0",
        title: "ScroogeCoin API",
        description:
          "API Documentation for ScroogeCoin.  The greatest ALT COIN on the Internet and the official coin to end the holidays!"
      }
    }
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ScroogeCoinWeb do
    pipe_through :browser
    live "/", HomeLive
    live "/balances", BalancesLive
    import Phoenix.LiveDashboard.Router
    live_dashboard "/dashboard", metrics: ScroogeCoinWeb.Telemetry
  end

  # Other scopes may use custom stacks.
  scope "/api", ScroogeCoinWeb do
    pipe_through :api
    post "/blocks", BlockController, :create
    get "/blocks", BlockController, :list
    get "/info", InfoController, :info
  end

  scope "/api/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI,
      otp_app: :scrooge_coin,
      swagger_file: "swagger.json"
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:scrooge_coin, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).

    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
