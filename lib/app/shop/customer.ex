defmodule App.Shop.Customer do
  use Ecto.Schema

  import Ecto.Changeset

  alias App.Repo

  @type t :: %__MODULE__{}

  schema "customers" do
    field :session_uid, :string
    field :uid, :string
    field :name, :string

    has_many :orders, App.Shop.Order,
      on_replace: :delete

    timestamps()
  end

  @spec changeset(t, map) :: Ecto.Changeset.t
  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:name, :session_uid])
    |> validate_required([:session_uid])
    |> Repo.put_uid()
  end
end
