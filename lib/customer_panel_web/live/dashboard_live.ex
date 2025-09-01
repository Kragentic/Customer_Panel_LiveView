defmodule CustomerPanelWeb.DashboardLive do
  use CustomerPanelWeb, :live_view
  import CustomerPanelWeb.DataTableComponent
  import CustomerPanelWeb.ChartComponents

  @stats [
    %{label: "Inbound Calls", value: "142", delta: "+12%"},
    %{label: "Outbound Calls", value: "89", delta: "-5%"},
    %{label: "Booked Appointments", value: "67", delta: "+8%"},
    %{label: "Revenue", value: "$12,450", delta: "+15%"},
    %{label: "Rescheduled", value: "12", delta: "+3%"},
    %{label: "Cancelled", value: "8", delta: "-2%"},
    %{label: "Sync Errors", value: "3", delta: "-1%"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    rows = [
      %{id: "1", when: "2025-08-24 14:12", dir: "Inbound", from: "YELP", sentiment: "positive", disposition: "Appointment", summary: "Asked for deep clean. Scheduled.", recording: "/recordings/1.mp3"},
      %{id: "2", when: "2025-08-24 15:30", dir: "Outbound", from: "GOOGLE", sentiment: "neutral", disposition: "Callback", summary: "Requested callback tomorrow.", recording: "/recordings/2.mp3"},
      %{id: "3", when: "2025-08-25 09:45", dir: "Inbound", from: "WEBSITE", sentiment: "negative", disposition: "Not Interested", summary: "Price too high.", recording: "/recordings/3.mp3"}
    ]

    columns = [
      %{key: :when, label: "When"},
      %{key: :dir, label: "Direction"},
      %{key: :from, label: "Channel"},
      %{key: :disposition, label: "Disposition"},
      %{key: :summary, label: "Summary"}
    ]

    map_points = [
      %{lat: 33.7455, lng: -117.8677, label: "Santa Ana"},
      %{lat: 33.8353, lng: -117.9145, label: "Fullerton"},
      %{lat: 33.6595, lng: -117.9988, label: "Huntington Beach"}
    ]

    chart_data = %{
      labels: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul"],
      datasets: [
        %{label: "uv", data: [400, 300, 200, 278, 189, 239, 349], borderColor: "#8884d8", backgroundColor: "rgba(136,132,216,0.2)", borderWidth: 2, tension: 0.4},
        %{label: "pv", data: [240, 139, 980, 390, 480, 380, 430], borderColor: "#82ca9d", backgroundColor: "rgba(130,202,157,0.2)", borderWidth: 2, tension: 0.4}
      ]
    }

    bar_data = %{
      labels: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul"],
      datasets: [
        %{label: "sales", data: [4000, 3000, 2000, 2780, 1890, 2390, 3490], backgroundColor: "#8884d8"}
      ]
    }

    {:ok,
     assign(socket,
       stats: @stats,
       rows: rows,
       columns: columns,
       selected_rows: [],
       map_points: map_points,
       chart_data: chart_data,
       bar_data: bar_data
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="grid grid-cols-1 sm:grid-cols-3 lg:grid-cols-4 gap-6">
        <%= for stat <- @stats do %>
          <div
            phx-click="stat_click"
            phx-value-label={stat.label}
            class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow duration-200 cursor-pointer"
          >
            <p class="text-sm font-medium text-gray-600"><%= stat.label %></p>
            <p class="text-3xl font-bold text-gary-900 mt-1"><%= stat.value %></p>
            <p class={"text-sm mt-1 " <> if(String.starts_with?(stat.delta, "+"), do: "text-green-600", else: "text-red-600")}>
              <%= stat.delta %> vs last week
            </p>
          </div>
        <% end %>
      </div>

      <div class="grid grid-cols-2 gap-6 mt-[30px]">
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-4 h-[450px]">
          <h2 class="text-lg font-semibold text-gray-800 mb-4">Heatmap</h2>
          <div id="heatmap" data-points={Jason.encode!(@map_points)} phx-hook="LeafletMap" class="h-[380px] rounded-lg overflow-hidden"></div>
        </div>
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-4 h-[450px]">
          <div class="h-[400px] rounded-lg overflow-hidden">
            <.data_table
              id="dashboard-table"
              title="Recent activities"
              rows={@rows}
              columns={@columns}
              selected_rows={@selected_rows}
              row_click_event="row_click"
            />
          </div>
        </div>
      </div>

      <div class="grid grid-cols-2 gap-6 mt-[30px]">
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-4 h-[450px]">
          <.line_chart id="trends-chart" title="Trends" data={@chart_data} />
        </div>
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-4 h-[450px]">
          <.bar_chart id="sales-chart" title="Monthly Sales" data={@bar_data} />
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("stat_click", %{"label" => label}, socket) do
    IO.inspect(label, label: "Clicked stat")
    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_row", %{"id" => id}, socket) do
    selected = socket.assigns.selected_rows
    new_selected = if id in selected, do: Enum.reject(selected, &(&1 == id)), else: [id | selected]
    {:noreply, assign(socket, selected_rows: new_selected)}
  end

  @impl true
  def handle_event("toggle_all", _params, socket) do
    rows = socket.assigns.rows
    selected = socket.assigns.selected_rows
    all_ids =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {item, i} -> to_string(row_id(item, i)) end)

    new_selected = if length(selected) == length(rows), do: [], else: all_ids
    {:noreply, assign(socket, selected_rows: new_selected)}
  end

  @impl true
  def handle_event("row_click", %{"id" => id}, socket) do
    {:noreply, put_flash(socket, :info, "Row clicked: #{id}")}
  end

  @impl true
  def handle_event("row_actions", %{"id" => id}, socket) do
    {:noreply, put_flash(socket, :info, "Actions for #{id}")}
  end

  @impl true
  def handle_event("export_csv", _params, socket) do
    count = length(socket.assigns.selected_rows)
    {:noreply, put_flash(socket, :info, "Exporting #{count} row(s) to CSV")}
  end

  @impl true
  def handle_event("assign_selected", _params, socket) do
    {:noreply, put_flash(socket, :info, "Assign action on selected rows")}
  end

  @impl true
  def handle_event("merge_selected", _params, socket) do
    {:noreply, put_flash(socket, :info, "Merge action on selected rows")}
  end

  @impl true
  def handle_event("tag_selected", _params, socket) do
    {:noreply, put_flash(socket, :info, "Tag action on selected rows")}
  end

  @impl true
  def handle_event("add_new", _params, socket) do
    {:noreply, put_flash(socket, :info, "Add New clicked")}
  end

  @impl true
  def handle_event("toggle_columns", _params, socket) do
    {:noreply, put_flash(socket, :info, "Columns clicked")}
  end

  defp row_id(item, index) do
    cond do
      Map.has_key?(item, :id) and item.id -> item.id
      Map.has_key?(item, :time) and item.time -> item.time
      Map.has_key?(item, :received) and item.received -> item.received
      Map.has_key?(item, :started) and item.started -> item.started
      true -> "row-" <> Integer.to_string(index)
    end
  end
end
