defmodule AppWeb.Views.Cart do
  use AppWeb, :view

  alias App.Schema.Cart
  alias AppWeb.Views

  def render("view.json", %{cart: %Cart{} = cart}) do
    %{data: render_one(cart, Views.Cart, "cart.json", as: :cart)}
  end

  def render("cart.json", %{cart: %Cart{} = cart}) do
    line_items = if Ecto.assoc_loaded?(cart.line_items), do: render_many(cart.line_items, Views.LineItem, "line_item.json", as: :line_item), else: []
    customer = if Ecto.assoc_loaded?(cart.customer), do: render_one(cart.customer, Views.Customer, "customer.json", as: :customer), else: nil
    %{
      id: cart.id,
      uid: cart.uid,
      customer: customer,
      customer_id: cart.customer_id,
      inserted_at: cart.inserted_at,
      updated_at: cart.updated_at,
      paid_date: cart.paid_date,
      line_items: line_items
    }
  end
end
