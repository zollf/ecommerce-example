defmodule AppWeb.Controllers.Fallback do
  use AppWeb, :controller
  alias AppWeb.Views

  @doc """
  Error call
  """
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(Views.Changeset)
    |> render("error.json", changeset: changeset)
  end
end
