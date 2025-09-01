defmodule CustomerPanelWeb.DataTableComponent do
  @moduledoc """
  Reusable data table component with selection, sticky header and action toolbar.

  Attributes:
    * :id - DOM id for the table wrapper (default: "data-table")
    * :title - table title (required)
    * :rows - list of maps representing row data (required)
    * :columns - list of maps [%{key: :field, label: "Label"}] (required)
    * :selected_rows - list of selected row ids (default: [])
    * :toggle_row_event - event name to toggle a single row (default: "toggle_row")
    * :toggle_all_event - event name to toggle select all/none (default: "toggle_all")
    * :row_click_event - event name to notify parent when a data cell is clicked (optional)
    * :export_event, :assign_event, :merge_event, :tag_event - action event names

  Behavior:
    - Selection state is controlled by the parent LiveView via :selected_rows.
    - All events are sent to the parent LiveView (no target set), so define handle_event/3 there.
  """
  use Phoenix.Component
  use Gettext, backend: CustomerPanelWeb.Gettext

  # Use icon function from core components
  import CustomerPanelWeb.CoreComponents, only: [icon: 1]

  @type column :: %{required(:key) => atom() | String.t(), required(:label) => String.t()}

  attr :id, :string, default: "data-table"
  attr :title, :string, required: true
  attr :rows, :list, required: true
  attr :columns, :list, required: true
  attr :selected_rows, :list, default: []

  attr :toggle_row_event, :string, default: "toggle_row"
  attr :toggle_all_event, :string, default: "toggle_all"
  attr :row_click_event, :string, default: nil

  attr :export_event, :string, default: "export_csv"
  attr :assign_event, :string, default: "assign_selected"
  attr :merge_event, :string, default: "merge_selected"
  attr :tag_event, :string, default: "tag_selected"

  # Optional row id generator function: (row :: map, index :: integer) -> term
  attr :row_id, :any, default: &__MODULE__.default_row_id/2

  def data_table(assigns) do
    ~H"""
    <div id={@id} class="">
      <div :if={length(@selected_rows) > 0} class="bg-blue-50 border border-blue-200 rounded-md p-3 m-4 flex items-center justify-between">
        <div class="text-sm text-blue-800">{length(@selected_rows)} row(s) selected</div>
        <div class="flex space-x-2">
          <button phx-click={@export_event} class="inline-flex items-center px-3 py-1 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
            <.icon name="hero-arrow-down-tray" class="h-4 w-4 mr-1" /> Export CSV
          </button>
          <button phx-click={@assign_event} class="inline-flex items-center px-3 py-1 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">Assign</button>
          <button phx-click={@merge_event} class="inline-flex items-center px-3 py-1 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">Merge</button>
          <button phx-click={@tag_event} class="inline-flex items-center px-3 py-1 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">Tag</button>
        </div>
      </div>

      <div class="px-6 pb-[7px] border-b border-gray-200 flex justify-between">
        <h2 class="text-lg font-medium text-gray-900">{@title}</h2>
        <div class="flex items-center space-x-2">
          <button phx-click="add_new" class="inline-flex items-center px-3 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
            <.icon name="hero-plus" class="h-4 w-4 mr-1" /> Add New
          </button>
          <button phx-click="toggle_columns" class="inline-flex items-center px-3 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
            <.icon name="hero-adjustments-horizontal" class="h-4 w-4 mr-1" /> Columns
          </button>
        </div>
      </div>

      <div class="">
        <div class="h-[calc(400px-46px)] overflow-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50 sticky top-0 z-10">
              <tr>
                <th class="px-6 py-3">
                  <input
                    type="checkbox"
                    class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                    checked={@rows != [] and length(@selected_rows) == length(@rows)}
                    phx-click={@toggle_all_event}
                  />
                </th>
                <th :for={col <- @columns} class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  {col[:label]}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <%= for {item, i} <- Enum.with_index(@rows) do %>
                <% rid = @row_id.(item, i) |> to_string() %>
                <tr id={rid} class="border-b border-gray-200 hover:bg-gray-50">
                  <td class="px-6 py-4 whitespace-nowrap">
                    <input
                      type="checkbox"
                      class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                      checked={Enum.member?(@selected_rows, rid)}
                      phx-click={@toggle_row_event}
                      phx-value-id={rid}
                    />
                  </td>

                  <%= for col <- @columns do %>
                    <% key = col[:key] %>
                    <% val = Map.get(item, key) %>
                    <td phx-click={@row_click_event} phx-value-id={rid} class="px-6 py-4 whitespace-nowrap">
                      <%= if to_string(key) == "status" do %>
                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                          <%= Phoenix.HTML.Engine.html_escape(to_string(val)) %>
                        </span>
                      <% else %>
                        <span class="text-sm text-gray-900">
                          <%= if is_list(val), do: Enum.join(val, ", "), else: to_string(val || "") %>
                        </span>
                      <% end %>
                    </td>
                  <% end %>

                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    <button class="text-gray-400 hover:text-gray-600" phx-click="row_actions" phx-value-id={rid}>
                      <.icon name="hero-ellipsis-vertical" class="h-4 w-4" />
                    </button>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  # Default id resolution as per the original React behavior
  def default_row_id(item, index) do
    cond do
      Map.has_key?(item, :id) and item.id -> item.id
      Map.has_key?(item, :time) and item.time -> item.time
      Map.has_key?(item, :received) and item.received -> item.received
      Map.has_key?(item, :started) and item.started -> item.started
      true -> "row-" <> Integer.to_string(index)
    end
  end
end
