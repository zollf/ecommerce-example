defmodule App.Catalogue.Product do
  use Ecto.Schema

  import Ecto.Changeset

  alias App.Repo

  @type t :: %__MODULE__{}

  schema "products" do
    field :uid, :string
    field :title, :string
    field :sku, :string
    field :description, :string
    field :price, :float
    field :image, :string

    has_many :line_items, App.Shop.LineItem,
      on_replace: :delete

    timestamps()
  end

  @spec changeset(t, map) :: Ecto.Changeset.t
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:title, :sku, :description, :price, :image])
    |> validate_required([:title, :sku, :description, :price, :image])
    |> Repo.put_uid()
  end
end
