defmodule CustomerPanelWeb.LeadsLive do
  use CustomerPanelWeb, :live_view
  import CustomerPanelWeb.DataTableComponent
  import CustomerPanelWeb.FilterBarComponent

  @impl true
  def mount(_params, _session, socket) do
    columns = [
      %{key: :id, label: "ID"},
      %{key: :name, label: "Name"},
      %{key: :contact, label: "Contact"},
      %{key: :source, label: "Source"},
      %{key: :status, label: "Status"},
      %{key: :assignee, label: "Assignee"},
      %{key: :createdAt, label: "Created"},
      %{key: :type, label: "Type"},
      %{key: :service, label: "Service"},
      %{key: :sqFt, label: "Sq Ft"},
      %{key: :beds, label: "Beds"},
      %{key: :baths, label: "Baths"},
      %{key: :zip, label: "ZIP"},
      %{key: :price, label: "Price"},
      %{key: :lastTouch, label: "Last Touch"},
      %{key: :age, label: "Age"}
    ]

    rows = [
      %{
        id: "L-1001", name: "Jane Doe", contact: "jane@example.com", source: "Website", status: "New",
        assignee: "Agent A", createdAt: "2025-08-24", type: "House", service: "Cleaning",
        sqFt: 1800, beds: 3, baths: 2, zip: "92801", price: "$250", lastTouch: "2025-08-25", age: "1d"
      },
      %{
        id: "L-1002", name: "John Smith", contact: "+1 555-111", source: "Yelp", status: "Contacted",
        assignee: "Agent B", createdAt: "2025-08-23", type: "Apartment", service: "Move-out",
        sqFt: 900, beds: 2, baths: 1, zip: "92701", price: "$180", lastTouch: "2025-08-25", age: "2d"
      }
    ]

    filters = %{date_range: "Last 7 days", location: "All", channel: "All", status: []}
    {:ok, assign(socket, columns: columns, rows: rows, selected_rows: [], filters: filters)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.filter_bar filters={@filters} on_change="filter_change" on_toggle_status="toggle_status" />
      <.data_table
        id="leads-table"
        title="Leads"
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
    {:noreply, put_flash(socket, :info, "Lead row clicked: #{id}")}
  end

  @impl true
  def handle_event("toggle_row", %{"id" => id}, socket) do
    selected = socket.assigns.selected_rows
    new_selected = if id in selected, do: Enum.reject(selected, &(&1 == id)), else: [id | selected]
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

  @impl true
  def handle_event("toggle_all", _params, socket) do
    ids = Enum.map(Enum.with_index(socket.assigns.rows), fn {row, i} -> to_string(row_id(row, i)) end)
    new_selected = if length(socket.assigns.selected_rows) == length(socket.assigns.rows), do: [], else: ids
    {:noreply, assign(socket, selected_rows: new_selected)}
  end

  defp normalize_filter_params(%{"date_range" => v}), do: %{date_range: v}
  defp normalize_filter_params(%{"location" => v}), do: %{location: v}
  defp normalize_filter_params(%{"channel" => v}), do: %{channel: v}
  defp normalize_filter_params(%{"saved" => _v}), do: %{}
  defp normalize_filter_params(_), do: %{}

  defp row_id(item, index) do
    cond do
      Map.has_key?(item, :id) and item.id -> item.id
      true -> "row-" <> Integer.to_string(index)
    end
  end
end
