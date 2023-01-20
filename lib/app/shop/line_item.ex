defmodule App.Shop.LineItem do
  use Ecto.Schema

  import Ecto.Changeset

  alias App.Repo

  @type t :: %__MODULE__{}

  schema "line_items" do
    field :uid, :string
    field :qty, :integer

    belongs_to :order, App.Shop.Order,
      on_replace: :delete

    belongs_to :product, App.Catalogue.Product,
      on_replace: :delete

    timestamps()
  end

  @spec changeset(t, map) :: Ecto.Changeset.t
  def changeset(line_item, attrs) do
    line_item
    |> cast(attrs, [:qty, :product_id, :order_id])
    |> Repo.put_uid()
    |> validate_required([:uid, :qty])
  end

  @spec update_changeset(t, map) :: Ecto.Changeset.t
  def update_changeset(line_item, attrs) do
    line_item
    |> cast(attrs, [:qty])
    |> validate_required([:qty])
  end
end
