defmodule AppWeb.Components.CartSummary do
  use AppWeb, :live_component

  @impl true
  def render(%{summary: _} = assigns) do
    ~H"""
    <div>
      <h2>Cart</h2>
      Total Items: <%= @summary.total_qty %>
      <br/>
      Total Cost: <%= @summary.total_cost %>
      <br/>
    </div>
    """
  end
end
