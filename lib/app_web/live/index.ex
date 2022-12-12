defmodule AppWeb.Live.Index do
  use AppWeb, :live_view

  alias App.Repo
  alias App.Schema.{Customer, Product, LineItem}
  alias App.Models.Cart

  alias AppWeb.Components.{CartSummary, Feed}

  @feed "feed"

  @impl true
  def mount(_params, session, socket) do
    %{"customer_session_uid" => customer_session_uid} = session

    customer = Repo.get_by!(Customer, uid: customer_session_uid)
    cart = Cart.get_active_cart(customer)

    if connected?(socket) do
      Cart.subscribe(cart)
    end

    {:ok, assign(socket,
      cart: cart,
      summary: Cart.summary(cart),
      products: Repo.all(Product)
    )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={CartSummary}
        summary={@summary}
        id="my-cart"
      />
      <div class="row">
        <%= for product <- @products do %>
          <div class="col-sm-3">
            <.live_component
              module={AppWeb.Components.Product}
              product={product}
              line_item={nil}
              cart={assigns.cart}
              id={product.id}
            />
          </div>
        <% end %>
      </div>
      <.live_component module={Feed} id="feed" />
    </div>
    """
  end

  @impl true
  def handle_info({:updated_line_item, %LineItem{} = line_item}, %{assigns: assigns} = socket) do
    %{products: products, cart: cart} = assigns
    product = Enum.find(products, & &1.id == line_item.product_id)
    send_update AppWeb.Components.Product,
      id: product.id,
      line_item: line_item,
      cart: cart,
      product: product

    {:noreply, socket}
  end

  @impl true
  def handle_info({:removed_line_item, %LineItem{} = line_item}, %{assigns: assigns} = socket) do
    %{products: products, cart: cart} = assigns
    product = Enum.find(products, & &1.id == line_item.product_id)
    send_update AppWeb.Components.Product,
      id: product.id,
      line_item: nil,
      cart: cart,
      product: product

    {:noreply, socket}
  end

  def handle_info({:new_message, text}, socket) do
    send_update AppWeb.Components.Feed,
      id: "feed",
      feed: [text]
    {:noreply, socket}
  end

  def handle_info({:updated_summary, summary}, socket) do
    send_update AppWeb.Components.CartSummary,
      id: "my-cart",
      summary: summary
    {:noreply, socket}
  end
end
