defmodule AppWeb.Views.Product do
  use AppWeb, :view

  alias App.Catalogue.Product
  alias AppWeb.Views

  def render("index.json", %{products: products}) do
    %{data: render_many(products, Views.Product, "product.json", as: :product)}
  end

  def render("view.json", %{product: %Product{} = product}) do
    %{data: render_one(product, Views.Product, "product.json", as: :product)}
  end

  def render("product.json", %{product: %Product{} = product}) do
    %{
      id: product.id,
      uid: product.uid,
      inserted_at: product.inserted_at,
      updated_at: product.updated_at,
      image: product.image,
      title: product.title,
      sku: product.sku,
      price: product.price
    }
  end
end
