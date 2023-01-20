defmodule AppWeb.Views.Cart do
  use AppWeb, :view

  alias App.Shop.Order
  alias AppWeb.Views

  def render("view.json", %{cart: %Order{} = cart}) do
    %{data: render_one(cart, Views.Cart, "order.json", as: :cart)}
  end

  def render("order.json", %{order: %Order{} = order}) do
    line_items = if Ecto.assoc_loaded?(order.line_items), do: render_many(order.line_items, Views.LineItem, "line_item.json", as: :line_item), else: []
    customer = if Ecto.assoc_loaded?(order.customer), do: render_one(order.customer, Views.Customer, "customer.json", as: :customer), else: nil
    %{
      id: order.id,
      uid: order.uid,
      customer: customer,
      customer_id: order.customer_id,
      inserted_at: order.inserted_at,
      updated_at: order.updated_at,
      paid_date: order.paid_date,
      line_items: line_items
    }
  end
end
