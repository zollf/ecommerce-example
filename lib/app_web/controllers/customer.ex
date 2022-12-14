defmodule AppWeb.Controllers.Customer do
  use AppWeb, :controller

  import Plug.Conn

  alias App.Schema.{Customer}
  alias AppWeb.Views
  alias App.Repo

  def me(conn, _params) do
    customer_session_uid = get_session(conn, :customer_session_uid)
    customer = Repo.get_by!(Customer, uid: customer_session_uid)

    conn
    |> put_view(Views.Customer)
    |> render("view.json", customer: customer)
  end
end
