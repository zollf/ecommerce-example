defmodule App.Shop.Order do
  use Ecto.Schema

  import Ecto.Changeset

  alias App.Repo

  @type t :: %__MODULE__{}

  schema "orders" do
    field :uid, :string
    field :paid_date, :naive_datetime

    has_many :line_items, App.Shop.LineItem,
      on_replace: :delete

    belongs_to :customer, App.Shop.Customer,
      on_replace: :delete

    timestamps()
  end

  @spec changeset(t, map) :: Ecto.Changeset.t
  def changeset(cart, attrs) do
    cart
    |> cast(attrs, [:customer_id, :paid_date])
    |> Repo.put_uid()
  end
end
