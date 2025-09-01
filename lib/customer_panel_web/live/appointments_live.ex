defmodule CustomerPanelWeb.AppointmentsLive do
  use CustomerPanelWeb, :live_view
  import CustomerPanelWeb.DataTableComponent

  @locations ["All", "CA", "TX"]

  @impl true
  def mount(_params, _session, socket) do
    events = sample_events()

    socket =
      socket
      |> assign(
        events: events,
        location: "All",
        show: true,
        focus_id: nil,
        locations: @locations
      )
      |> compute_filtered()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="">
      <%= if @show do %>
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-4">
          <div class="flex items-center justify-between mb-2">
            <div class="flex items-center gap-3">
              <label class="text-sm text-gray-700">Location</label>
              <form phx-change="set_location" class="inline">
                <select name="location" class="border border-gray-300 rounded-md px-3 py-1 text-sm" value={@location}>
                  <option :for={loc <- @locations} selected={loc == @location}>{loc}</option>
                </select>
              </form>
            </div>
          </div>

          <.data_table
            id="appointments-table"
            title="Appointments"
            rows={@rows}
            columns={[
              %{key: :when, label: "When"},
              %{key: :title, label: "Title"},
              %{key: :location, label: "Location"},
              %{key: :status, label: "Status"},
              %{key: :channel, label: "Channel"},
              %{key: :assignees, label: "Assignees"}
            ]}
            selected_rows={[]}
            row_click_event="row_click"
          />
        </div>
      <% else %>
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-4">
          <div class="mb-3">
            <button phx-click="back" class="text-sm text-blue-700 hover:underline inline-flex items-center">
              <span class="mr-1">&#8592;</span> BACK
            </button>
          </div>
          <div phx-hook="FullCalendarPanel" id="calendar" data-events={Jason.encode!(@filtered_events)} data-focus-id={@focus_id}></div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("set_location", %{"location" => loc}, socket) do
    socket = socket |> assign(location: loc) |> compute_filtered()
    {:noreply, socket}
  end

  @impl true
  def handle_event("row_click", %{"id" => id}, socket) do
    {:noreply, assign(socket, focus_id: id, show: false)}
  end

  @impl true
  def handle_event("back", _params, socket) do
    {:noreply, assign(socket, show: true)}
  end

  @impl true
  def handle_event("calendar_event_click", %{"id" => id}, socket) do
    {:noreply, assign(socket, focus_id: id)}
  end

  # Simple calendar-like list grouped by date, highlighting focused event
  attr :events, :list, required: true
  attr :focus_id, :string, default: nil
  def calendar_panel(assigns) do
    grouped = Enum.group_by(assigns.events, fn e -> Date.to_string(e.date) end)
    assigns = assign(assigns, grouped: grouped)

    ~H"""
    <div class="space-y-4">
      <div :for={{date, es} <- Enum.sort_by(@grouped, fn {d, _} -> d end)} class="">
        <div class="text-sm font-semibold text-gray-700 mb-1">{date}</div>
        <div class="space-y-2">
          <div :for={e <- Enum.sort_by(es, & &1.time)}
               class={[
                 "border rounded-md px-3 py-2 flex items-center justify-between",
                 @focus_id == e.id && "border-blue-400 bg-blue-50" || "border-gray-200 bg-white"
               ]}
          >
            <div>
              <div class="text-sm font-medium text-gray-900">{e.title}</div>
              <div class="text-xs text-gray-600">{e.time} • {e.location} • {e.channel}</div>
            </div>
            <div class="flex items-center gap-3">
              <span class="text-xs px-2 py-0.5 rounded-full bg-blue-100 text-blue-800">{e.status}</span>
              <button phx-click="calendar_event_click" phx-value-id={e.id} class="text-xs text-blue-700 hover:underline">Focus</button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Helpers
  defp compute_filtered(socket) do
    loc = socket.assigns.location
    events = socket.assigns.events

    filtered = if loc == "All", do: events, else: Enum.filter(events, &(&1.location == loc))

    rows = Enum.map(filtered, fn e ->
      start = Date.to_iso8601(e.date) <> "T" <> e.time <> ":00"
      %{
        id: e.id,
        when: Date.to_string(e.date) <> " " <> e.time,
        title: e.title,
        location: e.location,
        status: e.status,
        channel: e.channel,
        assignees: e.assignees,
        start: start
      }
    end)

    assign(socket, filtered_events: filtered, rows: rows)
  end

  defp sample_events do
    [
      %{
        id: "A-1",
        date: ~D[2025-08-24],
        time: "14:12",
        title: "Deep Clean",
        location: "CA",
        status: "Scheduled",
        channel: "Phone",
        assignees: ["Alex", "Sam"]
      },
      %{
        id: "A-2",
        date: ~D[2025-08-24],
        time: "15:30",
        title: "Move-out",
        location: "TX",
        status: "Pending",
        channel: "Chat",
        assignees: ["Jamie"]
      },
      %{
        id: "A-3",
        date: ~D[2025-08-25],
        time: "09:45",
        title: "Standard Clean",
        location: "CA",
        status: "Completed",
        channel: "Web",
        assignees: ["Taylor"]
      }
    ]
  end

  defp locations, do: @locations
end
