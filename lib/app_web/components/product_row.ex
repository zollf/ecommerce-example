defmodule AppWeb.Components.ProductRow do
  use AppWeb, :live_component

  alias App.Shop

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def render(%{product: _, line_item: _, cart: _} = assigns) do
    ~H"""
    <tr>
      <.td><%= @product.title %></.td>
      <.td>$<%= @product.price %></.td>
      <.td><%= @line_item |> qty %></.td>
      <.td>$<%= @line_item |> total %></.td>
      <.td>
        <.button
          link_type="button"
          size="xs"
          label="View"
          color="light"
          phx-click="minus"
          phx-target={@myself}
        >
          <HeroiconsV1.Solid.minus class="w-4 h-6" />
        </.button>

        <.button
          link_type="button"
          size="xs"
          label="View"
          color="light"
          phx-click="add"
          phx-target={@myself}
        >
          <HeroiconsV1.Solid.plus class="w-4 h-6" />
        </.button>

        <.button
          link_type="button"
          size="xs"
          label="View"
          color="light"
          phx-click="remove"
          phx-target={@myself}
        >
          <HeroiconsV1.Solid.trash class="w-4 h-6" />
        </.button>
      </.td>
    </tr>
    """
  end

  def qty(nil), do: 0
  def qty(line_item), do: line_item.qty

  def total(nil), do: 0
  def total(line_item), do: line_item.product.price * line_item.qty

  @impl true
  def handle_event("add", _, %{assigns: assigns} = socket) do
    %{product: product, cart: cart} = assigns
    case assigns do
      %{line_item: nil} -> Shop.increase_qty_of_item_in_order(cart, product)
      %{line_item: line_item} -> Shop.increase_qty_of_item_in_order(cart, line_item)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("minus", _, %{assigns: assigns} = socket) do
    %{cart: cart} = assigns
    case assigns do
      %{line_item: nil} -> nil
      %{line_item: line_item} -> Shop.decrease_qty_of_item_in_order(cart, line_item)
    end

    {:noreply, socket}
  end

  def handle_event("remove", _, %{assigns: assigns} = socket) do
    %{cart: cart} = assigns
    case assigns do
      %{line_item: nil} -> nil
      %{line_item: line_item} -> Shop.decrease_qty_of_item_in_order(cart, line_item, line_item.qty)
    end

    {:noreply, socket}
  end
end
