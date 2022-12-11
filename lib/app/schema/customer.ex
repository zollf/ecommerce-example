defmodule App.Schema.Customer do
  use Ecto.Schema

  import Ecto.Changeset

  alias App.Repo

  @type t :: %__MODULE__{}

  schema "customers" do
    field :uid, :string
    field :name, :string

    has_many :carts, App.Schema.Cart,
      on_replace: :delete

    timestamps()
  end

  @spec changeset(t, map) :: Ecto.Changeset.t
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:name])
    |> Repo.put_uid()
  end
end
