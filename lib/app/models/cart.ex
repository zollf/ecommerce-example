defmodule App.Models.Cart do
  use App.Models, schema: App.Schema.Cart

  import Ecto.Query

  alias App.{Schema, Models, Repo}

  def get_or_create_cart(session) do
    case get_cart(session) do
      nil ->
        IO.puts("[#{session}]: Creating cart")
        Models.Cart.create(%{session: session})
      cart ->
        IO.puts("[#{session}]: Fetched existing cart")
        {:ok, cart}
    end
  end

  def get_cart(session) do
    Repo.one(from c in Schema.Cart, order_by: c.inserted_at, where: c.session == ^session and is_nil(c.paid_date) )
  end

  @spec save_product(
    Schema.Cart.t,
    Schema.Product.t,
    integer
  ) :: {:ok, Schema.t}
  | {:error, Ecto.Changeset.t}
  | {:not_allowed, String.t}
  | {:not_found, String.t}

  @doc """
  Saves a product to a cart by adding a line item
  """
  def save_product(%{paid_date: nil} = cart, product, 0) do
    remove_product(cart, product)
  end

  def save_product(%{paid_date: nil} = cart, product, qty) do
    case Models.LineItem.one(cart_id: cart.id, product_id: product.id) do
      {:not_found, _msg} -> Models.LineItem.create(%{cart: cart.id, product: product.id, qty: qty})
      {:ok, line_item} -> line_item
        |> Schema.LineItem.changeset(%{qty: qty})
        |> Repo.update
    end
  end

  def save_product(%{paid_date: paid_date}, _product, 0) do
    {:not_allowed, "Cart has already been paid for on #{NaiveDateTime.to_string(paid_date)}"}
  end

  @spec remove_product(
    Schema.Cart.t,
    Schema.Product.t
  ) :: {:ok, Schema.t}
  | {:error, Ecto.Changeset.t}
  | {:not_allowed, String.t}
  | {:not_found, String.t}

  @doc """
  Removes product form a cart by finding matching line item
  """
  def remove_product(%{paid_date: nil} = cart, product) do
    with {:ok, line_item} <- Models.LineItem.one(cart_id: cart.id, product_id: product.id) do
      Repo.delete line_item
    end
  end

  def remove_product(%{paid_date: paid_date}, _product) do
    {:not_allowed, "Cart has already been paid for on #{NaiveDateTime.to_string(paid_date)}"}
  end

  @spec pay(
    Schema.Cart.t
  ) :: {:ok, Schema.Cart.t}
  | {:not_found, String.t}
  | {:not_allowed, String.t}

  @doc """
  Marks a cart as paid
  """
  def pay(%{paid_date: nil} = cart) do
    Models.Cart.update(%{paid_date: Repo.now()}, id: cart.id)
  end

  def pay(%{paid_date: paid_date}) do
    {:not_allowed, "Cart has already been paid for on #{NaiveDateTime.to_string(paid_date)}"}
  end
end
