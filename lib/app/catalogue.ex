defmodule App.Catalogue do
  alias App.Repo
  alias App.Catalogue.Product

  @spec all_products :: [Product.t()]
  def all_products(), do: Repo.all(Product)

  def create_product(params) do
    %Product{}
    |> Product.changeset(params)
    |> Repo.insert()
  end
end
