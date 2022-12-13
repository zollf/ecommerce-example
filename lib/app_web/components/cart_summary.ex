defmodule AppWeb.Components.CartSummary do
  use AppWeb, :live_component

  alias App.Models.Cart

  @impl true
  def render(%{summary: _, cart: _} = assigns) do
    ~H"""
    <div>
      <h2>Cart</h2>
      Customer UID: <%= @cart.customer.uid || 0 %>
      <br />
      Cart UID: <%= @cart.uid || 0 %>
      <br />
      Total Items: <%= @summary.total_qty || 0 %>
      <br/>
      Total Cost: $<%= @summary.total_cost || 0 %>
      <br />
      Total Spent: $<%= @summary.total_spent || 0 %>
      <br/>
      <button type="button" class="btn btn-primary d-flex align-items-center" phx-click="pay" phx-target={@myself}>Pay</button>
    </div>
    """
  end

  @impl true
  def handle_event("pay", _, %{assigns: assigns} = socket) do
    %{cart: cart} = assigns
    Cart.pay(cart)
    {:noreply, socket}
  end
end
