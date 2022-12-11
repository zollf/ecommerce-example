defmodule App.Schema.Cart do
  use Ecto.Schema

  import Ecto.Changeset

  alias App.Repo

  @type t :: %__MODULE__{}

  schema "carts" do
    field :uid, :string
    field :paid_date, :naive_datetime

    has_many :line_items, App.Schema.LineItem,
      on_replace: :delete

    belongs_to :customer, App.Schema.Customer,
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
