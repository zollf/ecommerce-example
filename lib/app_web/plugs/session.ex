defmodule AppWeb.Plugs.SessionUID do
  use AppWeb, :controller

  import Plug.Conn

  def fetch_session_uid(conn, _opts) do
    conn
    |> ensure_session_uid()
  end

  defp ensure_session_uid(conn) do
    if get_session(conn, :session_uid) do
      conn
    else
      put_session(conn, :session_uid, Ecto.UUID.generate())
    end
  end
end
