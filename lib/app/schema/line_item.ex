defmodule App.Schema.LineItem do
  use Ecto.Schema

  import Ecto.Changeset

  alias App.Repo

  @type t :: %__MODULE__{}

  schema "line_items" do
    field :uid, :string
    field :qty, :integer

    belongs_to :cart, App.Schema.Cart
    belongs_to :product, App.Schema.Product

    timestamps()
  end

  @spec changeset(t, map) :: Ecto.Changeset.t
  def changeset(line_item, attrs) do
    line_item
    |> Repo.preload(:product)
    |> cast(attrs, [:qty])
    |> Repo.put_uid()
    |> put_assoc(:product, get_assoc_product(Map.get(attrs, :product) || nil))
    |> put_assoc(:cart, get_assoc_cart(Map.get(attrs, :cart) || nil))
    |> validate_required([:uid, :qty])
  end

  defp get_assoc_product(nil), do: nil
  defp get_assoc_product(id) do
    Repo.get_by(App.Schema.Product, id: id)
  end

  defp get_assoc_cart(nil), do: nil
  defp get_assoc_cart(id) do
    Repo.get_by(App.Schema.Cart, id: id)
  end
end
