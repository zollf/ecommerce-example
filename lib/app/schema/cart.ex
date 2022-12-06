defmodule App.Schema.Cart do
  use Ecto.Schema

  import Ecto.Changeset

  alias App.Repo

  @type t :: %__MODULE__{}

  schema "carts" do
    field :uid, :string
    field :session, :string
    field :paid_date, :naive_datetime

    has_many :line_items, App.Schema.LineItem,
      on_replace: :delete

    timestamps()
  end

  def changeset(cart, attrs) do
    cart
    |> cast(attrs, [:session, :paid_date])
    |> validate_required([:session])
    |> Repo.put_uid()
  end
end
