defmodule AppWeb.Controllers.Product do
  use AppWeb, :controller

  alias App.Repo
  alias App.Schema.Product
  alias AppWeb.Views

  def index(conn, _params) do
    conn
    |> put_view(Views.Product)
    |> render("index.json", products: Repo.all(Product))
  end
end
