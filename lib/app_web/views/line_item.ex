defmodule AppWeb.Views.LineItem do
  use AppWeb, :view

  alias App.Shop.LineItem
  alias AppWeb.Views

  def render("index.json", %{line_items: line_items}) do
    %{data: render_many(line_items, Views.LineItem, "line_item.json", as: :line_item)}
  end

  def render("view.json", %{line_item: %LineItem{} = line_item}) do
    %{data: render_one(line_item, Views.LineItem, "line_item.json", as: :line_item)}
  end

  def render("line_item.json", %{line_item: %LineItem{} = line_item}) do
    product = if Ecto.assoc_loaded?(line_item.product), do: render_one(line_item.product, Views.Product, "product.json", as: :product), else: nil
    %{
      id: line_item.id,
      uid: line_item.uid,
      qty: line_item.qty,
      inserted_at: line_item.inserted_at,
      updated_at: line_item.updated_at,
      product_id: line_item.product_id,
      product: product
    }
  end
end
