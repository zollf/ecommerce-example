defmodule AppWeb.Plugs.CustomerSession do
  use AppWeb, :controller

  import Plug.Conn

  alias App.Schema.Customer
  alias App.Repo

  def fetch_customer_session(conn, _opts) do
    conn
    |> ensure_customer_session()
  end

  defp ensure_customer_session(conn) do
    if get_session(conn, :customer_session_uid) do
      customer_session_uid = get_session(conn, :customer_session_uid)
      case Repo.get_by(Customer, uid: customer_session_uid) do
        nil -> create_customer_session(conn)
        _ -> conn
      end
    else
      conn
      |> create_customer_session
    end
  end

  defp create_customer_session(conn) do
    customer = %Customer{}
    |> Customer.changeset(%{})
    |> Repo.insert!

    put_session(conn, :customer_session_uid, customer.uid)
  end
end
