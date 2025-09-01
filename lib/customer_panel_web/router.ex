defmodule CustomerPanelWeb.Router do
  use CustomerPanelWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CustomerPanelWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CustomerPanelWeb do
    pipe_through :browser
    live "/dashboard", DashboardLive, :index
    live "/leads", LeadsLive, :index
    live "/customers", CustomersLive, :index
    live "/appointments", AppointmentsLive, :index
    live "/conversations/calls", CallsLive, :index
    live "/conversations/chats", ChatsLive, :index
    live "/conversations/email", EmailLive, :index
    live "/conversations/sms", SMSLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", CustomerPanelWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:customer_panel, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CustomerPanelWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
