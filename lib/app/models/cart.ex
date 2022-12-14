defmodule App.Models.Cart do
  import Ecto.Query
  import Ecto.Changeset

  alias App.Repo
  alias App.Schema.{LineItem, Product, Cart, Customer}

  @max_qty 99
  @feed_topic "feed"

  @doc """
  Retrieves the active cart for the given customer.

    * `customer` - Customer to fetch active cart for.

  ## Example

      iex> customer = %Customer{id: 1}
      iex> Cart.get_active_cart(customer)
      %Cart{id: 1, customer_id: 1}

  """
  @spec get_active_cart(customer :: Customer.t) :: Cart.t
  def get_active_cart(%Customer{} = customer) do
    query = from cart in Cart,
      join: customer in assoc(cart, :customer),
      join: line_item in assoc(cart, :line_items),
      join: product in assoc(line_item, :product),
      where: cart.customer_id == ^customer.id and is_nil(cart.paid_date),
      order_by: cart.inserted_at,
      preload: [customer: customer, line_items: {line_item, product: product}]

    case Repo.one query do
      nil -> %Cart{}
        |> Cart.changeset(%{customer_id: customer.id})
        |> put_assoc(:customer, customer)
        |> put_assoc(:line_items, [])
        |> Repo.insert!
      cart -> cart
    end
  end

  @doc """
  Increases quantity of a line item, given a line item or a product.

    * `cart` - Cart to increase quantity of line item from.
    * `line_item` or `product` the item to increase quantity of. If product is supplied line_item will be searched.
    * `qty` - Quantity to increase by. Default is 1.

  ## Examples

      # Increasing with line_item param
      iex> cart = %Cart{id: 1}
      iex> product = %Product{id: 1, title: "Bike", sku: "bike", description: "Bike desc", image: "bike.png"}
      iex> line_item = %LineItem{id: 1, product_id 1, cart_id: 1, qty: 2}
      iex> Cart.increase_qty(cart, line_item)
      %LineItem{id: 1, product_id 1, cart_id: 1, qty: 3}

      # Increase with product param
      iex> cart = %Cart{id: 1}
      iex> product = %Product{id: 1, title: "Bike", sku: "bike", description: "Bike desc", image: "bike.png"}
      iex> line_item = %LineItem{id: 1, product_id 1, cart_id: 1, qty: 2}
      iex> Cart.increase_qty(cart, product, 4)
      %LineItem{id: 1, product_id 1, cart_id: 1, qty: 6}

  """
  @spec increase_qty(Cart.t, LineItem.t | Product.t, Integer.t) :: LineItem.t
  def increase_qty(_, _, qty \\ 1)

  def increase_qty(%Cart{} = cart, %LineItem{} = line_item, qty) when cart.id == line_item.cart_id do
    line_item
    |> LineItem.update_changeset(%{qty: min(@max_qty, line_item.qty + qty)})
    |> Repo.update!
    |> broadcast_updated_line_item(cart)
    |> broadcast_to_feed(cart, :increased)
  end

  def increase_qty(%Cart{} = cart, %Product{} = product, qty) do
    query = from line_item in LineItem,
      join: product in assoc(line_item, :product),
      where: ^cart.id == line_item.cart_id and ^product.id == line_item.product_id,
      preload: [product: product]

    case Repo.one(query) do
      nil -> %LineItem{}
        |> LineItem.changeset(%{cart_id: cart.id, product_id: product.id, qty: max(1, min(@max_qty, qty))})
        |> put_assoc(:product, product)
        |> Repo.insert!
        |> broadcast_updated_line_item(cart)
        |> broadcast_to_feed(cart, :added)
      line_item -> increase_qty(cart, line_item, qty)
    end
  end

  @doc """
  Decreases quantity of a line item, given a line item or a product.
  Item will be removed if the quantity goes below 0.

    * `cart` - Cart to decrease quantity of line item from.
    * `line_item` or `product` the item to decrease quantity of. If product is supplied line_item will be searched.
    * `qty` - Quantity to decrease by. Default is 1.

  ## Examples

      # Decreasing with line_item param
      iex> cart = %Cart{id: 1}
      iex> product = %Product{id: 1, title: "Bike", sku: "bike", description: "Bike desc", image: "bike.png"}
      iex> line_item = %LineItem{id: 1, product_id 1, cart_id: 1, qty: 2}
      iex> Cart.decrease_qty(cart, line_item)
      %LineItem{id: 1, product_id 1, cart_id: 1, qty: 1}

      # Decreasing with product param
      iex> cart = %Cart{id: 1}
      iex> product = %Product{id: 1, title: "Bike", sku: "bike", description: "Bike desc", image: "bike.png"}
      iex> line_item = %LineItem{id: 1, product_id 1, cart_id: 1, qty: 2}
      iex> Cart.decrease_qty(cart, product, 4)
      # Item should be delete, the result will be `Ecto.Schema` as we use `Repo.delete!/1`
      %LineItem{id: 1, product_id 1, cart_id: 1, qty: 6}

  """
  @spec decrease_qty(Cart.t, LineItem.t | Product.t, Integer.t) :: LineItem.t
  def decrease_qty(_, _, qty \\ 1)

  def decrease_qty(%Cart{} = cart, %LineItem{} = line_item, qty)
    when line_item.qty - qty <= 0 and cart.id == line_item.cart_id do
    line_item
    |> Repo.preload(:product)
    |> Repo.delete!
    |> broadcast_removed_line_item(cart)
    |> broadcast_to_feed(cart, :removed)
  end

  def decrease_qty(%Cart{} = cart, %LineItem{} = line_item, qty)
    when cart.id == line_item.cart_id do
    line_item
    |> Repo.preload(:product)
    |> LineItem.update_changeset(%{qty: max(0, line_item.qty - qty)})
    |> Repo.update!
    |> broadcast_updated_line_item(cart)
    |> broadcast_to_feed(cart, :decreased)
  end

  def decrease_qty_of_product(%Cart{} = cart, %Product{} = product, qty) do
    Repo.get_by!(LineItem, cart_id: cart.id, product_id: product.id)
    |> decrease_qty(qty)
  end

  @doc """
  Updates the cart to be paid with the current time.

    * `cart` - Cart to be payed.

  ## Examples

      iex> cart = %Cart{id: 1}
      iex> Cart.pay(cart)
      %Cart{id: 1, paid_date: ~N[2000-01-01 23:00:07]}

  """
  @spec pay(Cart.t) :: Cart.t
  def pay(%Cart{paid_date: nil} = cart) do
    cart
    |> Cart.changeset(%{paid_date: Repo.now()})
    |> Repo.update!
    |> broadcast_payment
  end

  @doc """
  Gets summary of a given cart.

    * `cart` - Cart to get summary of.

  """
  def summary(%Cart{} = cart) do
    {total_cost, total_qty} = Repo.one(
      from l in LineItem,
      where: l.cart_id == ^cart.id,
      inner_join: p in Product, on: p.id == l.product_id,
      select: {sum(p.price * l.qty), sum(l.qty)}
    )
    {total_spent} = Repo.one(
      from l in LineItem,
      inner_join: p in Product, on: p.id == l.product_id,
      inner_join: c in Cart, on: c.id == l.cart_id,
      where: c.customer_id == ^cart.customer_id and not is_nil(c.paid_date),
      select: {sum(p.price * l.qty)}
    )
    %{total_cost: total_cost, total_qty: total_qty, total_spent: total_spent}
  end

  @doc """
  Subscribes to cart and feed updates.
  """
  def subscribe(%Cart{} = cart) do
    Phoenix.PubSub.subscribe(App.PubSub, topic(cart))
    Phoenix.PubSub.subscribe(App.PubSub, topic_feed())
  end

  defp topic_feed(), do: @feed_topic
  defp topic(%Cart{} = cart), do: "customer:#{cart.customer_id}"

  defp broadcast(%Cart{} = cart, message), do: Phoenix.PubSub.broadcast(App.PubSub, topic(cart), message)
  defp broadcast_feed(message), do: Phoenix.PubSub.broadcast(App.PubSub, topic_feed(), message)

  defp feed_msg(%Cart{} = cart, %Product{} = product, :removed), do: "#{customer_name(cart.customer)} removed #{product.title} from their cart."
  defp feed_msg(%Cart{} = cart, %Product{} = product, :added), do: "#{customer_name(cart.customer)} added #{product.title} to their cart."
  defp feed_msg(%Cart{} = cart, %Product{} = product, :increased), do: "#{customer_name(cart.customer)} increased the amount of #{product.title} within their cart."
  defp feed_msg(%Cart{} = cart, %Product{} = product, :decreased), do: "#{customer_name(cart.customer)} decreased the amount of #{product.title} within their cart."

  defp customer_name(%Customer{name: nil} = customer), do: customer.uid
  defp customer_name(%Customer{name: name} = _), do: name

  defp broadcast_to_feed(%LineItem{} = line_item, %Cart{} = cart, action) do
    broadcast_feed({:new_message, feed_msg(cart, line_item.product, action)})
    line_item
  end

  defp broadcast_payment(%Cart{} = cart) do
    cart_summary = summary(cart)
    %{total_cost: total_cost, total_qty: total_qty} = cart_summary
    broadcast_feed({:new_message, "#{customer_name(cart.customer)} purchased #{total_qty} items for $#{total_cost}"})

    new_cart = get_active_cart(cart.customer)
    broadcast(cart, {:updated_cart, new_cart})
    broadcast(cart, {:updated_summary, summary(new_cart)})

    cart
  end

  defp broadcast_updated_line_item(%LineItem{} = line_item, %Cart{} = cart) do
    broadcast(cart, {:updated_line_item, line_item})
    broadcast(cart, {:updated_summary, summary(cart)})
    line_item
  end

  defp broadcast_removed_line_item(%LineItem{} = line_item, %Cart{} = cart) do
    broadcast(cart, {:removed_line_item, line_item})
    broadcast(cart, {:updated_summary, summary(cart)})
    line_item
  end
end
