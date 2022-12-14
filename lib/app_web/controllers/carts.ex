defmodule AppWeb.Controllers.Cart do
  use AppWeb, :controller

  import Plug.Conn

  alias App.Schema.{Customer, Product}
  alias App.Models.Cart
  alias App.Repo

  alias AppWeb.Views

  def index(conn, _params) do
    customer_session_uid = get_session(conn, :customer_session_uid)
    customer = Repo.get_by!(Customer, uid: customer_session_uid)
    cart = Cart.get_active_cart(customer)

    conn
    |> put_view(Views.Cart)
    |> render("view.json", cart: cart)
  end

  def add_product(conn, %{"product_id" => product_id} = _params) do
    case Repo.get_by(Product, id: product_id) do
      nil -> nil
      product ->
        customer_session_uid = get_session(conn, :customer_session_uid)
        line_item = Repo.get_by!(Customer, uid: customer_session_uid)
        |> Cart.get_active_cart()
        |> Cart.increase_qty(product)

        conn
        |> put_view(Views.LineItem)
        |> render("line_item.json", line_item: line_item)
    end
  end
end
