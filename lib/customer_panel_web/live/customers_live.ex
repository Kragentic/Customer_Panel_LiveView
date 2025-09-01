defmodule CustomerPanelWeb.CustomersLive do
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
      %{key: :status, label: "Status"},       # not in mock; safe to keep
      %{key: :assignee, label: "Assignee"},   # not in mock; safe to keep
      %{key: :city, label: "City"},
      %{key: :zip, label: "ZIP"},
      %{key: :firstSeen, label: "First Seen"},
      %{key: :lastJob, label: "Last Job"},
      %{key: :jobs, label: "Jobs"},
      %{key: :spend, label: "Spend"},
      %{key: :tags, label: "Tags"}
    ]

    # Sample mock data akin to mockCustomers
    rows = [
      %{
        id: "C-2001", name: "Acme Corp", contact: "ops@acme.com", source: "Website",
        city: "Anaheim", zip: "92801", firstSeen: "2025-01-12", lastJob: "2025-08-01",
        jobs: 5, spend: "$2,450", tags: ["commercial", "recurring"]
      },
      %{
        id: "C-2002", name: "Jane Roe", contact: "+1 555-222", source: "Yelp",
        city: "Santa Ana", zip: "92701", firstSeen: "2024-11-03", lastJob: "2025-07-20",
        jobs: 2, spend: "$620", tags: ["residential"]
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
        id="customers-table"
        title="Customers"
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
    {:noreply, put_flash(socket, :info, "Customer row clicked: #{id}")}
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
