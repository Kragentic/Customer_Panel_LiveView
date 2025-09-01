defmodule CustomerPanelWeb.ChartComponents do
  @moduledoc """
  Reusable chart components using Chart.js via LiveView hooks.

  The line_chart component expects a JSON-serializable map with:
    %{
      labels: ["Jan", ...],
      datasets: [
        %{label: "uv", data: [...], borderColor: "#hex", backgroundColor: "rgba(...)"},
        ...
      ]
    }

  The bar_chart component expects the same structure but is rendered as bars.
  """
  use Phoenix.Component

  @doc """
  Renders a responsive line chart canvas bound to the LineChart JS hook.

  Attributes:
    * id (required): unique DOM id for the canvas
    * data (required): map with labels and datasets (will be JSON-encoded)
    * class: Tailwind classes for the canvas container size/styling
    * title: optional title above the chart
  """
  attr :id, :string, required: true
  attr :data, :map, required: true
  attr :class, :string, default: "h-[380px] rounded-lg overflow-hidden relative"
  attr :title, :string, default: nil

  def line_chart(assigns) do
    ~H"""
    <div>
      <h2 :if={@title} class="text-lg font-semibold text-gray-800 mb-4">{@title}</h2>
      <div class={@class}>
        <canvas id={@id} class="w-full h-full" phx-hook="LineChart" data-chart={Jason.encode!(@data)}></canvas>
      </div>
    </div>
    """
  end

  @doc """
  Renders a responsive bar chart canvas bound to the BarChart JS hook.

  Attributes:
    * id (required): unique DOM id for the canvas
    * data (required): map with labels and datasets (will be JSON-encoded)
    * class: Tailwind classes for the canvas container size/styling
    * title: optional title above the chart
  """
  attr :id, :string, required: true
  attr :data, :map, required: true
  attr :class, :string, default: "h-[380px] rounded-lg overflow-hidden relative"
  attr :title, :string, default: nil

  def bar_chart(assigns) do
    ~H"""
    <div>
      <h2 :if={@title} class="text-lg font-semibold text-gray-800 mb-4">{@title}</h2>
      <div class={@class}>
        <canvas id={@id} class="w-full h-full" phx-hook="BarChart" data-chart={Jason.encode!(@data)}></canvas>
      </div>
    </div>
    """
  end

  @doc """
  Tremor BarChart (React) via LiveView hook.

  Attributes:
    * id (required)
    * rows (required): list of maps, e.g., [%{"date" => "Jan 23", "SolarPanels" => 2890, "Inverters" => 2338}, ...]
    * index (required): the key used for x-axis labels (string or atom), e.g., "date"
    * categories (required): list of keys (strings or atoms) for series, e.g., ["SolarPanels", "Inverters"]
    * colors (optional): list of Tremor color names (e.g., ["blue", "emerald"]) default ["blue"]
    * title (optional)
    * class (optional): container sizing classes; Tremor chart receives className="h-full w-full"
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :index, :any, required: true
  attr :categories, :list, required: true
  attr :colors, :list, default: ["red"]
  attr :title, :string, default: nil
  attr :class, :string, default: "h-[380px] rounded-lg overflow-hidden relative"


  def tremor_bar_chart(assigns) do
   IO.inspect(assigns, label: "TremorBar Assigns") 
    tremor_cfg = %{
      data: assigns.rows,
      index: assigns.index,
      categories: assigns.categories,
      colors: assigns.colors,
      className: "h-full w-full"
    }

    assigns = assign(assigns, tremor_cfg: tremor_cfg)

    ~H"""
    <div>
      <h2 :if={@title} class="text-lg font-semibold text-gray-800 mb-4">{@title}</h2>
      <div class={@class}>
        <div id={@id} phx-hook="TremorBar" data-chart={Jason.encode!(@tremor_cfg)} class="h-full w-full " ></div>
      </div>
    </div>
    """
  end

  @doc """
  Tremor LineChart (React) via LiveView hook.

  Attributes:
    * id (required)
    * rows (required): list of maps
    * index (required): x-axis key
    * categories (required): list of series keys
    * colors (optional): Tremor color names (defaults to ["sky"]) 
    * title (optional)
    * class (optional)
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :index, :any, required: true
  attr :categories, :list, required: true
  attr :colors, :list, default: ["sky"]
  attr :title, :string, default: nil
  attr :class, :string, default: "h-[380px] rounded-lg overflow-hidden relative"

  def tremor_line_chart(assigns) do

    tremor_cfg = %{
      data: assigns.rows,
      index: assigns.index,
      categories: assigns.categories,
      colors: assigns.colors,
      className: "h-full w-full"
    }

    assigns = assign(assigns, tremor_cfg: tremor_cfg)

    ~H"""
    <div>
      <h2 :if={@title} class="text-lg font-semibold text-gray-800 mb-4">{@title}</h2>
      <div class={@class}>
        <div id={@id} phx-hook="TremorLine" data-chart={Jason.encode!(@tremor_cfg)} class="h-full w-full"></div>
      </div>
    </div>
    """
  end

  @doc """
  Tremor Table (React) via LiveView hook.

  Attributes:
    * id (required)
    * rows (required): list of maps for table rows
    * columns (required): list like [%{key: :field, label: "Label"}] or ["field", ...]
    * title (optional)
    * class (optional)
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :columns, :list, required: true
  attr :title, :string, default: nil
  attr :class, :string, default: "h-[400px] rounded-lg overflow-hidden relative"

  def tremor_table(assigns) do
    cfg = %{
      rows: assigns.rows,
      columns:
        assigns.columns
        |> Enum.map(fn col ->
          cond do
            is_map(col) -> %{key: Map.get(col, :key) || Map.get(col, "key"), label: Map.get(col, :label) || Map.get(col, "label")}
            is_atom(col) or is_binary(col) -> %{key: col, label: to_string(col)}
            true -> %{key: "", label: ""}
          end
        end),
      className: "w-full"
    }

    assigns = assign(assigns, tremor_table_cfg: cfg)

    ~H"""
    <div>
      <h2 :if={@title} class="text-lg font-semibold text-gray-800 mb-4">{@title}</h2>
      <div class={@class}>
        <div id={@id} phx-hook="TremorTable" data-table={Jason.encode!(@tremor_table_cfg)} class="h-full w-full"></div>
      </div>
    </div>
    """
  end

  # Helpers
  defp tremor_to_chartjs(rows, index_key, categories) do
    labels = Enum.map(rows, fn row -> to_string(get_field(row, index_key)) end)
    palette = [
      "#3b82f6", "#22c55e", "#f97316", "#a855f7", "#ef4444", "#14b8a6", "#eab308", "#8b5cf6"
    ]

    datasets =
      categories
      |> Enum.with_index()
      |> Enum.map(fn {cat, i} ->
        color = Enum.at(palette, rem(i, length(palette)))
        %{
          label: to_string(cat),
          data: Enum.map(rows, fn row -> normalize_number(get_field(row, cat)) end),
          backgroundColor: color,
          borderColor: color,
          borderWidth: 1
        }
      end)

    %{labels: labels, datasets: datasets}
  end

  defp get_field(row, key) do
    cond do
      is_atom(key) && Map.has_key?(row, key) -> Map.get(row, key)
      is_binary(key) && Map.has_key?(row, key) -> Map.get(row, key)
      is_binary(key) && Map.has_key?(row, String.to_atom(key)) -> Map.get(row, String.to_atom(key))
      is_atom(key) && Map.has_key?(row, Atom.to_string(key)) -> Map.get(row, Atom.to_string(key))
      true -> nil
    end
  end

  defp normalize_number(v) when is_number(v), do: v
  defp normalize_number(v) when is_binary(v) do
    case Float.parse(v) do
      {n, _} -> n
      :error -> 0
    end
  end

  defp normalize_number(_), do: 0
end
