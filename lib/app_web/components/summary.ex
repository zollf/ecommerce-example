defmodule AppWeb.Components.Summary do
  use AppWeb, :live_component

  alias PetalComponents.HeroiconsV1
  alias App.Shop

  @impl true
  def render(%{customer_summary: _, order_summary: _, cart: _} = assigns) do
    ~H"""
    <div class="grid grid-cols-2 gap-4">
      <div>
        <div class="flex justify-between mb-4">
          <.h2>Customer</.h2>
          <.button with_icon link_type="button" phx-click="reset" phx-target={@myself}>
            <HeroiconsV1.Solid.refresh solid class="w-5 h-5" /> Reset
          </.button>
        </div>
        <.table>
          <.tr>
            <.td>UID</.td>
            <.td><%= String.slice(@cart.customer.uid, 0..7) %></.td>
          </.tr>
          <.tr>
            <.td>Total Items</.td>
            <.td><%= @customer_summary.total_items || 0 %></.td>
          </.tr>
          <.tr>
            <.td>Total Spent</.td>
            <.td>$<%= @customer_summary.total_spent || 0 %></.td>
          </.tr>
        </.table>
      </div>
      <div>
        <div class="flex justify-between mb-4">
          <.h2>Cart</.h2>
          <.button with_icon link_type="button" disabled={!has_items(@order_summary)} phx-click="pay" phx-target={@myself}>
            <HeroiconsV1.Solid.shopping_cart solid class="w-5 h-5" /> Pay
          </.button>
        </div>
        <.table>
          <.tr>
            <.td>UID</.td>
            <.td><%= String.slice(@cart.uid, 0..7) %></.td>
          </.tr>
          <.tr>
            <.td>Total Quantity</.td>
            <.td><%= @order_summary.total_qty || 0 %></.td>
          </.tr>
          <.tr>
            <.td>Total Cost</.td>
            <.td>$<%= @order_summary.total_cost || 0 %></.td>
          </.tr>
        </.table>
      </div>
    </div>
    """
  end

  @spec has_items(Map.t) :: boolean
  def has_items(order_summary), do: order_summary.total_qty != nil and order_summary.total_qty > 0

  @impl true
  def handle_event("pay", _, %{assigns: assigns} = socket) do
    %{cart: cart, order_summary: order_summary} = assigns
    if has_items(order_summary) do
      Shop.pay_and_create_new_cart(cart)
    end
    {:noreply, socket}
  end

  @impl true
  def handle_event("reset", _, %{assigns: assigns} = socket) do
    %{cart: cart} = assigns
    Shop.reset_customer(cart.customer)
    {:noreply, socket}
  end
end
