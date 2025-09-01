defmodule CustomerPanelWeb.SidebarComponent do
  use Phoenix.Component
  import CustomerPanelWeb.CoreComponents, only: [icon: 1]

  # nav link helper
  attr :label, :string, required: true
  attr :icon, :string, required: true
  attr :to, :string, required: true
  attr :active, :boolean, default: false

  def nav_link(assigns) do
    ~H"""
    <a href={@to}
      class={[
        "w-full flex items-center px-3 py-1 text-sm rounded-md",
        if(@active,
          do: "bg-blue-100 text-blue-900",
          else: "text-gray-600 hover:bg-gray-100 hover:text-gray-900"
        )
      ]}
    >
      <.icon name={@icon} class="h-4 w-4 mr-[6px]" />
      <%= @label %>
    </a>
    """
  end

  # current active path passed from layout/liveview
  attr :active_path, :string, default: nil
  def sidebar(assigns) do
    ~H"""
    <div class="fixed inset-y-0 left-0 z-50 w-64 bg-white shadow-lg transform
                transition-transform duration-300 ease-in-out
                lg:translate-x-0 lg:static lg:inset-0">

      <!-- Header -->
      <div class="flex items-center justify-between h-16 px-4 border-b border-gray-200">
        <div class="flex items-center">
          <span class="text-lg font-semibold">Betty Miller Cleaning</span>
        </div>
        <!-- Mobile close button (you can wire this up later with JS hooks) -->
        <button class="lg:hidden text-gray-500 hover:text-gray-700">
          ✕
        </button>
      </div>

      <!-- Nav -->
      <nav class="mt-1 px-2 space-y-1">
        <.nav_link to="/dashboard" label="Dashboard" icon="hero-chart-bar" active={@active_path == "/dashboard"} />
        <.nav_link to="/leads" label="Leads" icon="hero-users" active={@active_path == "/leads"} />
        <.nav_link to="/customers" label="Customers" icon="hero-users" active={@active_path == "/customers"} />
        <.nav_link to="/appointments" label="Appointments" icon="hero-calendar-days" active={@active_path == "/appointments"} />

        <div class="px-3 py-2 text-xs font-semibold text-gray-500 uppercase mt-2">
          Conversations
        </div>
        <div class="ml-2 space-y-1">
          <.nav_link to="/conversations/calls" label="Calls" icon="hero-phone" active={@active_path == "/conversations/calls"} />
          <.nav_link to="/conversations/chats" label="Chats" icon="hero-chat-bubble-left-right" active={@active_path == "/conversations/chats"} />
          <.nav_link to="/conversations/email" label="Email" icon="hero-envelope" active={@active_path == "/conversations/email"} />
          <.nav_link to="/conversations/sms" label="SMS" icon="hero-chat-bubble-left" active={@active_path == "/conversations/sms"} />
        </div>
      </nav>
    </div>
    """
  end
end
