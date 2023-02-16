defmodule App.Shop do
  import Ecto.Query
  import Ecto.Changeset

  alias App.Repo
  alias App.Shop.{Order, LineItem, Customer}
  alias App.Catalogue.Product

  @max_qty 99

  @spec create_new_order(Customer.t()) :: Order.t()
  def create_new_order(%Customer{} = customer) do
    %Order{}
    |> Order.changeset(%{customer_id: customer.id})
    |> put_assoc(:customer, customer)
    |> put_assoc(:line_items, [])
    |> Repo.insert!()
  end

  @spec create_new_customer(String.t()) :: Customer.t()
  def create_new_customer(session_uid) when is_binary(session_uid) do
    %Customer{}
    |> Customer.changeset(%{session_uid: session_uid})
    |> Repo.insert!()
  end

  @spec create_new_cart(App.Shop.Customer.t()) :: App.Shop.Order.t()
  def create_new_cart(%Customer{} = customer) do
    customer
    |> create_new_order
    |> broadcast_new_cart
    |> broadcast_updated_order_summary
  end

  @spec get_customers_active_cart(Customer.t()) :: Order.t()
  def get_customers_active_cart(%Customer{} = customer) do
    query =
      from order in Order,
        join: customer in assoc(order, :customer),
        left_join: line_item in assoc(order, :line_items),
        left_join: product in assoc(line_item, :product),
        where: order.customer_id == ^customer.id and is_nil(order.paid_date),
        order_by: [desc: order.inserted_at],
        preload: [
          customer: customer,
          line_items: {line_item, product: product, order: {order, customer: customer}}
        ]

    case Enum.at(Repo.all(query), 0) do
      nil -> create_new_order(customer)
      order -> order
    end
  end

  @spec get_active_customer(String.t()) :: Customer.t()
  def get_active_customer(session_uid) when is_binary(session_uid) do
    query =
      from customer in Customer,
        where: customer.session_uid == ^session_uid,
        order_by: [desc: customer.inserted_at]

    case Enum.at(Repo.all(query), 0) do
      nil -> create_new_customer(session_uid)
      customer -> customer
    end
  end

  @spec increase_qty_of_item_in_order(
          Order.t(),
          Product.t() | LineItem.t(),
          Integer.t()
        ) :: LineItem.t()

  def increase_qty_of_item_in_order(_, _, qty \\ 1)

  def increase_qty_of_item_in_order(%Order{} = order, %LineItem{} = line_item, qty)
      when order.id == line_item.order_id do
    line_item
    |> LineItem.update_changeset(%{qty: min(@max_qty, line_item.qty + qty)})
    |> Repo.update!()
    |> broadcast_line_item_update(:increase_item_qty)
    |> broadcast_updated_order_summary
  end

  def increase_qty_of_item_in_order(%Order{} = order, %Product{} = product, qty) do
    query =
      from line_item in LineItem,
        join: product in assoc(line_item, :product),
        join: order in assoc(line_item, :order),
        where: ^order.id == line_item.order_id and ^product.id == line_item.product_id,
        preload: [product: product, order: order]

    case Repo.one(query) do
      nil ->
        %LineItem{}
        |> LineItem.changeset(%{
          order_id: order.id,
          product_id: product.id,
          qty: max(1, min(@max_qty, qty))
        })
        |> put_assoc(:product, product)
        |> put_assoc(:order, order)
        |> Repo.insert!()
        |> broadcast_line_item_update(:new_item)
        |> broadcast_updated_order_summary

      line_item ->
        increase_qty_of_item_in_order(order, line_item, qty)
    end
  end

  @spec decrease_qty_of_item_in_order(
          Order.t(),
          Product.t() | LineItem.t(),
          Integer.t()
        ) :: LineItem.t()
  def decrease_qty_of_item_in_order(_, _, qty \\ 1)

  def decrease_qty_of_item_in_order(%Order{} = order, %LineItem{} = line_item, qty)
      when line_item.qty - qty <= 0 and order.id == line_item.order_id do
    line_item
    |> Repo.preload(:product)
    |> Repo.delete!()
    |> broadcast_line_item_update(:removed_item)
    |> broadcast_updated_order_summary
  end

  def decrease_qty_of_item_in_order(%Order{} = order, %LineItem{} = line_item, qty)
      when order.id == line_item.order_id do
    line_item
    |> Repo.preload(:product)
    |> LineItem.update_changeset(%{qty: max(0, line_item.qty - qty)})
    |> Repo.update!()
    |> broadcast_line_item_update(:decrease_item_qty)
    |> broadcast_updated_order_summary
  end

  def decrease_qty_of_item_in_order(%Order{} = order, %Product{} = product, qty) do
    %LineItem{}
    |> Repo.get_by!(order_id: order.id, product_id: product.id)
    |> decrease_qty_of_item_in_order(qty)
  end

  @spec pay_for_order(Order.t()) :: Order.t()
  def pay_for_order(%Order{} = order) do
    order
    |> Order.changeset(%{paid_date: Repo.now()})
    |> Repo.update!()
    |> broadcast_updated_customer_summary
  end

  @spec pay_and_create_new_cart(Order.t()) :: Order.t()
  def pay_and_create_new_cart(%Order{} = order) do
    pay_for_order(order)
    |> Map.get(:customer)
    |> create_new_cart
  end

  @spec get_order_summary(Order.t()) :: map()
  def get_order_summary(%Order{} = order) do
    {total_cost, total_qty} =
      Repo.one(
        from l in LineItem,
          where: l.order_id == ^order.id,
          inner_join: p in Product,
          on: p.id == l.product_id,
          select: {sum(p.price * l.qty), sum(l.qty)}
      )

    %{total_cost: total_cost, total_qty: total_qty}
  end

  @spec get_customer_summary(Customer.t()) :: map()
  def get_customer_summary(%Customer{} = customer) do
    {total_spent, total_items} =
      Repo.one(
        from l in LineItem,
          inner_join: p in Product,
          on: p.id == l.product_id,
          inner_join: o in Order,
          on: o.id == l.order_id,
          where: o.customer_id == ^customer.id and not is_nil(o.paid_date),
          select: {sum(p.price * l.qty), sum(l.qty)}
      )

    %{total_spent: total_spent, total_items: total_items}
  end

  def reset_customer(%Customer{} = old_customer) do
    new_customer =
      %Customer{}
      |> Customer.changeset(%{session_uid: old_customer.session_uid})
      |> Repo.insert!()

    unsubscribe(old_customer)
    subscribe(new_customer)

    new_customer
    |> broadcast_updated_customer_summary
    |> create_new_cart
    |> broadcast_updated_order_summary
  end

  def topic(%Order{} = order), do: "customer:#{order.customer_id}"
  def topic(%Customer{} = customer), do: "customer:#{customer.id}"

  @spec subscribe(Customer.t()) :: :ok | {:error, term}
  def subscribe(%Customer{} = customer), do: Phoenix.PubSub.subscribe(App.PubSub, topic(customer))

  @spec unsubscribe(Customer.t()) :: :ok
  def unsubscribe(%Customer{} = customer),
    do: Phoenix.PubSub.unsubscribe(App.PubSub, topic(customer))

  def broadcast_new_cart(%Order{} = order) do
    Phoenix.PubSub.broadcast(App.PubSub, topic(order), {:new_cart, order})
    order
  end

  def broadcast_line_item_update(%LineItem{} = line_item, message) do
    Phoenix.PubSub.broadcast(App.PubSub, topic(line_item.order), {message, line_item})
    line_item
  end

  def broadcast_updated_order_summary(%LineItem{} = line_item) do
    Phoenix.PubSub.broadcast(
      App.PubSub,
      topic(line_item.order),
      {:updated_order_summary, get_order_summary(line_item.order)}
    )

    line_item
  end

  def broadcast_updated_order_summary(%Order{} = order) do
    Phoenix.PubSub.broadcast(
      App.PubSub,
      topic(order),
      {:updated_order_summary, get_order_summary(order)}
    )

    order
  end

  def broadcast_updated_customer_summary(%Order{} = order) do
    Phoenix.PubSub.broadcast(
      App.PubSub,
      topic(order.customer),
      {:updated_customer_summary, get_customer_summary(order.customer)}
    )

    order
  end

  def broadcast_updated_customer_summary(%Customer{} = customer) do
    Phoenix.PubSub.broadcast(
      App.PubSub,
      topic(customer),
      {:updated_customer_summary, get_customer_summary(customer)}
    )

    customer
  end
end
