defmodule AppWeb.Views.Index do
  use AppWeb, :live_view

  alias App.Models.Cart

  @impl true
  def mount(_params, session, socket) do
    session = session["session_uid"]

    Phoenix.PubSub.subscribe(App.PubSub, session)

    products = App.Models.Product.all()
    with {:ok, cart} <- Cart.get_or_create_cart(session) do
      {:ok, assign(socket,
        cart: cart,
        products: products,
        session: session
      )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="row">
        <h1>Global Transactions</h1>
      </div>

      <div class="row">
        <.live_component module={AppWeb.Components.MyCart} cart={assigns.cart} id="my-cart" />
        <%= for product <- @products do %>
          <div class="col-sm-3">
            <.live_component
              module={AppWeb.Components.Product}
              product={product}
              session={assigns.session}
              cart_id={assigns.cart.id}
              id={product.id}
            />
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_info({:updated_line_item, line_item, product}, socket) do
    send_update AppWeb.Components.Product,
      id: product.id,
      line_item: line_item,
      cart_id: socket.assigns.cart.id,
      session: socket.assigns.session,
      product: product

    {:noreply, socket}
  end
end
