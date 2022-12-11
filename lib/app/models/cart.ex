defmodule App.Models.Cart do
  import Ecto.Query

  alias App.Repo
  alias App.Schema.{LineItem, Product, Cart, Customer}

  @max_qty 99

  @doc """
  Retrieves the active cart for the given customer.

    * `customer` - Customer to fetch active cart for.

  ## Example

      iex> customer = %Customer{id: 1}
      iex> active_cart = Cart.get_active_cart(customer)

  """
  @spec get_active_cart(customer :: Customer.t) :: Cart.t
  def get_active_cart(%Customer{} = customer) do
    query = from c in Cart,
      where: c.customer_id == ^customer.id and is_nil(c.paid_date),
      order_by: c.inserted_at,
      preload: [:customer]

    case Repo.one query do
      nil -> %Cart{}
        |> Repo.preload(:customer)
        |> Cart.changeset(%{customer_id: customer.id})
        |> Repo.insert!
      cart -> cart
    end
  end

  @doc """
  Adds a product to the given cart.

    * `cart` - Cart to add product to.
    * `product` - Product to be added.
    * `qty` - Quantity of product to be added to cart. Default is 1.

  ## Examples

      iex> product = %Product{id: 1, title: "Bike", sku: "bike", description: "Bike desc", image: "bike.png"}
      iex> cart = %Cart{id: 1}
      iex> line_item = Cart.add_product(cart, product)

      # Adding multiple
      iex> product = %Product{id: 1, title: "Bike", sku: "bike", description: "Bike desc", image: "bike.png"}
      iex> cart = %Cart{id: 1}
      iex> line_item = Cart.add_product(cart, product, 10)

  """
  @spec add_product(Cart.t, Product.t, Integer.t) :: LineItem.t
  def add_product(%Cart{} = cart, %Product{} = product, qty \\ 1) do
    %LineItem{}
    |> LineItem.changeset(%{cart_id: cart.id, product_id: product.id, qty: max(1, qty)})
    |> Repo.insert!
    |> broadcast_updated_line_item(cart)
  end

  @doc """
  Increases quantity of a line item.
  """
  @spec increase_qty(Cart.t, LineItem.t | Product.t, Integer.t) :: LineItem.t
  def increase_qty(_, _, qty \\ 1)

  def increase_qty(%Cart{} = cart, %LineItem{} = line_item, qty) when cart.id == line_item.cart_id do
    line_item
    |> LineItem.update_changeset(%{qty: min(@max_qty, line_item.qty + qty)})
    |> Repo.update!
    |> broadcast_updated_line_item(cart)
  end

  def increase_qty(%Cart{} = cart, %Product{} = product, qty) do
    case Repo.get_by(LineItem, cart_id: cart.id, product_id: product.id) do
      nil -> add_product(cart, product, qty)
      line_item -> increase_qty(cart, line_item, qty)
    end
  end

  @doc """

  """
  @spec decrease_qty(Cart.t, LineItem.t | Product.t, Integer.t) :: LineItem.t
  def decrease_qty(_, _, qty \\ 1)
  def decrease_qty(%Cart{} = cart, %LineItem{} = line_item, qty)
    when line_item.qty - qty <= 0 and cart.id == line_item.cart_id do
    line_item
    |> Repo.delete!
    |> broadcast_removed_line_item(cart)
  end

  def decrease_qty(%Cart{} = cart, %LineItem{} = line_item, qty)
    when cart.id == line_item.cart_id do
    line_item
    |> LineItem.update_changeset(%{qty: max(0, line_item.qty - qty)})
    |> Repo.update!
    |> broadcast_updated_line_item(cart)
  end

  def decrease_qty_of_product(%Cart{} = cart, %Product{} = product, qty) do
    Repo.get_by!(LineItem, cart_id: cart.id, product_id: product.id)
    |> decrease_qty(qty)
  end

  @doc """
  Marks a cart as paid
  """
  @spec pay(Cart.t) :: Cart.t
  def pay(%Cart{paid_date: nil} = cart) do
    cart
    |> Cart.changeset(%{paid_date: Repo.now()})
    |> Repo.update!
  end

  def summary(%Cart{} = cart) do
    {total_cost, total_qty} = Repo.one(
      from l in LineItem,
      where: l.cart_id == ^cart.id,
      inner_join: p in Product, on: p.id == l.product_id,
      select: {sum(p.price * l.qty), sum(l.qty)}
    )
    %{total_cost: total_cost, total_qty: total_qty}
  end

  def topic(%Cart{} = cart), do: "customer:#{cart.customer_id}"
  def subscribe(%Cart{} = cart), do: Phoenix.PubSub.subscribe(App.PubSub, topic(cart))
  def broadcast(%Cart{} = cart, message), do: Phoenix.PubSub.broadcast(App.PubSub, topic(cart), message)

  @spec broadcast_updated_line_item(LineItem.t, Cart.t) :: LineItem.t
  def broadcast_updated_line_item(%LineItem{} = line_item, %Cart{} = cart) do
    broadcast(cart, {:updated_line_item, line_item})
    broadcast(cart, {:updated_summary, summary(cart)})
    line_item
  end

  @spec broadcast_removed_line_item(LineItem.t, Cart.t) :: LineItem.t
  def broadcast_removed_line_item(%LineItem{} = line_item, %Cart{} = cart) do
    broadcast(cart, {:removed_line_item, line_item})
    broadcast(cart, {:updated_summary, summary(cart)})
    line_item
  end
end
