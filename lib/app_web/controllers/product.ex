defmodule AppWeb.Controllers.Product do
  use AppWeb, :controller

  alias App.Catalogue
  alias AppWeb.Views

  action_fallback(AppWeb.Controllers.Fallback)

  def index(conn, _params) do
    conn
    |> put_view(Views.Product)
    |> render("index.json", products: Catalogue.all_products())
  end

  def create(conn, params) do
    with {:ok, product} <- Catalogue.create_product(params) do
      conn
      |> put_view(Views.Product)
      |> render("product.json", product: product)
    end
  end
end
