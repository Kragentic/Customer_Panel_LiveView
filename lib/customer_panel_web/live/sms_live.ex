defmodule CustomerPanelWeb.SMSLive do
  use CustomerPanelWeb, :live_view
  import CustomerPanelWeb.DataTableComponent
  import CustomerPanelWeb.FilterBarComponent

  @impl true
  def mount(_params, _session, socket) do
    columns = [
      %{key: :time, label: "Time"},
      %{key: :contact, label: "Contact"},
      %{key: :preview, label: "Preview"},
      %{key: :campaign, label: "Campaign"},
      %{key: :status, label: "Status"},
      %{key: :assignee, label: "Assignee"}
    ]

    # Sample rows akin to mockSMS
    rows = [
      %{
        time: "2025-08-24 08:21",
        contact: "+1 555-1010",
        preview: "Hi, can I get a quote for a 3BR?",
        campaign: "Welcome",
        status: "Open",
        assignee: "Alex"
      },
      %{
        time: "2025-08-24 12:11",
        contact: "Jane Roe",
        preview: "Following up on yesterday's call",
        campaign: "Nurture",
        status: "Pending",
        assignee: "Sam"
      },
      %{
        time: "2025-08-25 09:50",
        contact: "Bob Smith",
        preview: "Thanks, appointment confirmed",
        campaign: "Conversions",
        status: "Closed",
        assignee: "Jamie"
      }
    ]

    filters = %{date_range: "Last 7 days", location: "All", channel: "All", status: []}

    {:ok,
     assign(socket,
       columns: columns,
       rows: rows,
       selected_rows: [],
       filters: filters
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.filter_bar filters={@filters} on_change="filter_change" on_toggle_status="toggle_status" />
      <.data_table
        id="sms-table"
        title="SMS"
        rows={@rows}
        columns={@columns}
        selected_rows={@selected_rows}
        row_click_event="row_click"
      />
    </div>
    """
  end

  @impl true
  def handle_event("row_click", %{"id" => id}, socket) do
    {:noreply, put_flash(socket, :info, "SMS row clicked: #{id}")}
  end

  @impl true
  def handle_event("toggle_row", %{"id" => id}, socket) do
    selected = socket.assigns.selected_rows
    new_selected = if id in selected, do: Enum.reject(selected, &(&1 == id)), else: [id | selected]
    {:noreply, assign(socket, selected_rows: new_selected)}
  end

  @impl true
  def handle_event("toggle_all", _params, socket) do
    ids = Enum.map(Enum.with_index(socket.assigns.rows), fn {row, i} -> to_string(row_id(row, i)) end)
    new_selected = if length(socket.assigns.selected_rows) == length(socket.assigns.rows), do: [], else: ids
    {:noreply, assign(socket, selected_rows: new_selected)}
  end

  @impl true
  def handle_event("filter_change", params, socket) do
    filters = Map.merge(socket.assigns.filters, normalize_filter_params(params))
    {:noreply, assign(socket, filters: filters)}
  end

  @impl true
  def handle_event("toggle_status", %{"status" => status}, socket) do
    selected = Map.get(socket.assigns.filters, :status, [])
    new = if status in selected, do: Enum.reject(selected, &(&1 == status)), else: [status | selected]
    {:noreply, assign(socket, filters: Map.put(socket.assigns.filters, :status, new))}
  end

  defp normalize_filter_params(%{"date_range" => v}), do: %{date_range: v}
  defp normalize_filter_params(%{"location" => v}), do: %{location: v}
  defp normalize_filter_params(%{"channel" => v}), do: %{channel: v}
  defp normalize_filter_params(%{"saved" => _v}), do: %{}
  defp normalize_filter_params(_), do: %{}

  defp row_id(item, index) do
    cond do
      Map.has_key?(item, :id) and item.id -> item.id
      Map.has_key?(item, :time) and item.time -> item.time
      true -> "row-" <> Integer.to_string(index)
    end
  end
end
