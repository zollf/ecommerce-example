defmodule AppWeb.Components.ProductTable do
  use AppWeb, :live_component

  alias AppWeb.Components.ProductRow

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def render(%{products: _, cart: _} = assigns) do
    ~H"""
    <div>
      <.table>
        <.tr>
          <.th>Product</.th>
          <.th>Price</.th>
          <.th>Quantity</.th>
          <.th>Total</.th>
          <.th>Actions</.th>
        </.tr>
        <%= for product <- @products do %>
          <.live_component
            id={product.id}
            module={ProductRow}
            product={product}
            line_item={get_line_item(@cart, product)}
            cart={@cart}
          />
        <% end %>
      </.table>
    </div>
    """
  end

  def get_line_item(cart, product), do: Enum.find(cart.line_items, & &1.product_id == product.id)
end
