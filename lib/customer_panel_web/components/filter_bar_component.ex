defmodule CustomerPanelWeb.FilterBarComponent do
  @moduledoc """
  Filter bar component with Dashboard and Full variants.

  Attributes:
    * dashboard (boolean) - when true, renders compact variant (date_range + location)
    * filters (map) - current filter values: %{date_range: ..., location: ..., channel: ..., status: [...]}
    * date_ranges, locations, channels, statuses - option lists
    * on_change (string) - event to emit on select change (default: "filter_change")
    * on_toggle_status (string) - event to emit on status chip toggle (default: "toggle_status")
    * target - optional phx-target for events
  """
  use Phoenix.Component
  import CustomerPanelWeb.CoreComponents, only: [icon: 1]

  attr :dashboard, :boolean, default: false
  attr :filters, :map, default: %{}

  attr :date_ranges, :list, default: [
    "Today",
    "Yesterday",
    "Last 7 days",
    "Last 30 days",
    "This month",
    "Last month",
    "This quarter"
  ]

  attr :locations, :list, default: [
    "All",
    "CA",
    "TX",
    "NY",
    "FL"
  ]

  attr :channels, :list, default: [
    "All",
    "Phone",
    "Chat",
    "Email",
    "Web"
  ]

  attr :statuses, :list, default: [
    "New",
    "Contacted",
    "Qualified",
    "Unqualified",
    "Customer"
  ]

  attr :on_change, :string, default: "filter_change"
  attr :on_toggle_status, :string, default: "toggle_status"
  attr :target, :any, default: nil

  def filter_bar(assigns) do
    assigns =
      assigns
      |> assign_new(:selected_date_range, fn -> Map.get(assigns.filters, :date_range) || List.first(assigns.date_ranges) end)
      |> assign_new(:selected_location, fn -> Map.get(assigns.filters, :location) || List.first(assigns.locations) end)
      |> assign_new(:selected_channel, fn -> Map.get(assigns.filters, :channel) || List.first(assigns.channels) end)
      |> assign_new(:selected_statuses, fn -> Map.get(assigns.filters, :status) || [] end)

    ~H"""
    <%= if @dashboard do %>
      <div class="flex flex-wrap gap-4 mb-6 shadow-[0px_0px_3px_rgb(51,51,51,14%)] border-[#f2f3f7] p-2 bg-white rounded">
        <div class="flex items-center space-x-2">
          <.icon name="hero-calendar-mini" class="h-4 w-4 text-gray-500" />
          <.simple_select name="date_range" value={@selected_date_range} options={@date_ranges} on_change={@on_change} target={@target} />
        </div>
        <div class="flex items-center space-x-2">
          <.icon name="hero-map-pin-mini" class="h-4 w-4 text-gray-500" />
          <.simple_select name="location" value={@selected_location} options={@locations} on_change={@on_change} target={@target} />
        </div>
      </div>
    <% else %>
      <div class="flex flex-wrap gap-4 mb-6 rounded-sm bg-white shadow-[0px_0px_3px_rgb(51,51,51,14%)] border-[#f2f3f7] p-2">
        <div class="flex items-center space-x-2 relative">
          <.icon name="hero-calendar-mini" class="h-4 w-4 text-gray-500 absolute left-[17px] top-[7px]" />
          <.simple_select name="date_range" value={@selected_date_range} options={@date_ranges} on_change={@on_change} target={@target} class="pr-3 pl-[30px] py-1 text-sm" />
        </div>
        <div class="flex items-center space-x-2 relative">
          <.icon name="hero-map-pin-mini" class="h-4 w-4 text-gray-500 absolute left-[17px] top-[7px]" />
          <.simple_select name="location" value={@selected_location} options={@locations} on_change={@on_change} target={@target} class="pr-3 pl-[30px] py-1 text-sm" />
        </div>
        <div class="flex items-center space-x-2 relative">
          <.icon name="hero-chat-bubble-left-right-mini" class="h-4 w-4 text-gray-500 absolute left-[17px] top-[7px]" />
          <.simple_select name="channel" value={@selected_channel} options={@channels} on_change={@on_change} target={@target} class="pr-3 pl-[30px] py-1 text-sm" />
        </div>
        <div class="flex items-center space-x-2 ml-auto">
          <.icon name="hero-funnel-mini" class="h-4 w-4 text-gray-500" />
          <div class="flex flex-wrap gap-2">
            <button :for={s <- @statuses}
              type="button"
              phx-click={@on_toggle_status}
              phx-value-status={s}
              phx-target={@target}
              class={[
                "px-2 py-1 text-xs rounded-full border",
                (s in @selected_statuses) && "bg-blue-100 text-blue-800 border-blue-200" || "bg-gray-100 text-gray-800 border-gray-200"
              ]}
            >{s}</button>
          </div>
        </div>
        <div class="flex items-center space-x-2 relative">
          <.icon name="hero-star-mini" class="h-4 w-4 text-gray-500 absolute left-[17px] top-[7px]" />
          <.simple_select name="saved" value={"Saved Views"} options={["Saved Views", "CA–Last 7d", "TX–Calls only"]} on_change={@on_change} target={@target} class="pr-3 pl-[30px] py-1 text-sm" />
        </div>
      </div>
    <% end %>
    """
  end

  attr :name, :string, required: true
  attr :value, :string, required: true
  attr :options, :list, required: true
  attr :on_change, :string, required: true
  attr :target, :any, default: nil
  attr :class, :string, default: "border border-gray-300 rounded-md px-3 py-1 text-sm"
  defp simple_select(assigns) do
    ~H"""
    <form phx-change={@on_change} phx-target={@target} class="inline">
      <select name={@name} value={@value} class={@class}>
        <option :for={opt <- @options} value={opt} selected={opt == @value}>{opt}</option>
      </select>
    </form>
    """
  end
end
