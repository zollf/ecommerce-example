defmodule AppWeb.Live.Index do
  use AppWeb, :live_view

  alias App.Shop.{LineItem, Order}
  alias App.Shop
  alias App.Catalogue

  alias AppWeb.Components.{Summary, Feed, ProductRow, ProductTable}

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
      <div class="grid grid-cols-5 gap-4">
        <div class="col-span-3">
          <.h4>Customer UID: <%= String.slice(@cart.customer.uid, 0..7) %></.h4>
          <.h4>Cart UID: <%= String.slice(@cart.uid, 0..7) %></.h4>
          <div class="flex gap-2">
            <.button with_icon link_type="button" phx-click="reset">
              <HeroiconsV1.Solid.refresh solid class="w-5 h-5" /> Reset
            </.button>
            <.button with_icon link_type="button" disabled={!has_items(@order_summary)} phx-click="pay">
              <HeroiconsV1.Solid.shopping_cart solid class="w-5 h-5" />
              Pay $<%= @order_summary.total_cost || "0.00" %>
            </.button>
          </div>
        </div>
        <div class="col-span-3">
          <.live_component
            module={ProductTable}
            cart={@cart}
            products={@products}
            id="products"
          />
        </div>
        <div class="col-span-2 flex gap-4 flex-col">
          <.live_component module={Feed} id="feed" />
        </div>
      </div>
    </div>
    """
  end

  def has_items(order_summary), do: order_summary.total_qty != nil and order_summary.total_qty > 0

  @impl true
  def handle_info({:increase_item_qty, %LineItem{} = line_item}, socket) do
    product = find_line_item_in_products(socket.assigns.products, line_item)

    send_update(ProductRow,
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

    send_update(ProductRow,
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

    send_update(ProductRow,
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

    send_update(ProductRow,
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
