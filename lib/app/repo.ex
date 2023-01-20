defmodule App.Repo do
  use Ecto.Repo,
    otp_app: :app,
    adapter: Ecto.Adapters.Postgres

  import Ecto.Changeset

  @spec put_uid(Ecto.Changeset.t) :: Ecto.Changeset.t
  def put_uid(changeset), do: put_change(changeset, :uid, Ecto.UUID.generate())

  @spec now() :: NaiveDateTime.t
  def now(), do: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
end
