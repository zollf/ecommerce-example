defmodule AppWeb.Components.MyCart do
  use AppWeb, :live_component

  alias App.Models.Cart

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>Cart</h1>
      Session: <%= @cart.session %><br />
      Cart: <%= @cart.uid %>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    # IO.inspect(socket, limit: :infinity, structs: false)
    session = assigns.session
    with {:ok, cart} <- Cart.get_or_create_cart(session) do
      {:ok, assign(socket, Map.merge(assigns, %{cart: cart}))}
    end
  end
end
