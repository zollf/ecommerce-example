defmodule AppWeb.Plugs.Session do
  use AppWeb, :controller

  import Plug.Conn

  def fetch_session_uid(conn, _opts) do
    if get_session(conn, :session_uid) == nil do
      put_session(conn, :session_uid, Ecto.UUID.generate())
    else
      conn
    end
  end
end
