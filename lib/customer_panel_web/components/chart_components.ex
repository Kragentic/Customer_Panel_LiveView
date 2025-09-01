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
end
