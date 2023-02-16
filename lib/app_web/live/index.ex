defmodule AppWeb.Live.Index do
  use AppWeb, :live_view

  alias App.Shop.{LineItem, Order}
  alias App.Shop
  alias App.Catalogue

  alias AppWeb.Components.{Summary, Feed, Product}

  @impl true
  def mount(_params, session, socket) do
    IO.inspect(session)

    %{"session_uid" => session_uid} = session

    customer = Shop.get_active_customer(session_uid)
    cart = Shop.get_customers_active_cart(customer)

    if connected?(socket) do
      Shop.subscribe(customer)
    end

    {:ok,
      assign(socket,
        cart: cart,
        customer_summary: Shop.get_customer_summary(customer),
        order_summary: Shop.get_order_summary(cart),
        products: Catalogue.all_products()
      )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.h1 class="mb-12">
        <span class="text-transparent bg-clip-text bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500">
          Live eCommerce
        </span>
      </.h1>
      <div class="grid grid-cols-2 gap-4">
        <div>
          <div class="flex justify-between mb-4">
            <.h2>Products</.h2>
          </div>
          <div class="grid grid-cols-2 gap-4 auto-rows-min">
            <%= for product <- @products do %>
              <.live_component
                module={AppWeb.Components.Product}
                product={product}
                line_item={Enum.find(@cart.line_items, & &1.product_id == product.id)}
                cart={@cart}
                id={product.id}
              />
            <% end %>
          </div>
        </div>
        <div class="flex gap-4 flex-col">
          <.live_component
            module={Summary}
            order_summary={@order_summary}
            customer_summary={@customer_summary}
            cart={@cart}
            id="summary"
          />
          <.live_component module={Feed} id="feed" />
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_info({:increase_item_qty, %LineItem{} = line_item}, socket) do
    product = find_line_item_in_products(socket.assigns.products, line_item)

    send_update(Product,
      id: product.id,
      line_item: line_item,
      cart: socket.assigns.cart,
      product: product
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_item, %LineItem{} = line_item}, socket) do
    product = find_line_item_in_products(socket.assigns.products, line_item)

    send_update(Product,
      id: product.id,
      line_item: line_item,
      cart: socket.assigns.cart,
      product: product
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:removed_item, %LineItem{} = line_item}, socket) do
    product = find_line_item_in_products(socket.assigns.products, line_item)

    send_update(Product,
      id: product.id,
      line_item: nil,
      cart: socket.assigns.cart,
      product: product
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:decrease_item_qty, %LineItem{} = line_item}, socket) do
    product = find_line_item_in_products(socket.assigns.products, line_item)

    send_update(Product,
      id: product.id,
      line_item: line_item,
      cart: socket.assigns.cart,
      product: product
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:updated_customer_summary, customer_summary}, socket) do
    {:noreply, assign(socket,  customer_summary: customer_summary)}
  end

  @impl true
  def handle_info({:updated_order_summary, order_summary}, socket) do
    {:noreply, assign(socket,  order_summary: order_summary)}
  end

  @impl true
  def handle_info({:new_cart, %Order{} = order}, socket) do
    {:noreply, assign(socket, cart: order)}
  end

  defp find_line_item_in_products(products, %LineItem{} = line_item) do
    Enum.find(products, &(&1.id == line_item.product_id))
  end
end
