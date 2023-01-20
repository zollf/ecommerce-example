defmodule AppWeb.Plugs.Session do
  use AppWeb, :controller

  import Plug.Conn

  def fetch_session_uid(conn, _opts) do
    if get_session(conn, :uid) == nil do
      put_session(conn, :uid, Ecto.UUID.generate())
    end

    conn
  end
end
