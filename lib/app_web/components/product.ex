defmodule AppWeb.Components.Product do
  use AppWeb, :live_component

  alias App.Shop
  alias App.Shop.LineItem
  alias App.Catalogue.Product

  @type assign :: %{
    line_item: nil | LineItem,
    product: Product,
    cart: String.t,
  }

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def render(%{product: _, cart: _} = assigns) do
    ~H"""
    <div>
      <.card class="max-w-sm bg-gray-800" variant="outline">
        <.card_content class="max-w-sm relative" heading={@product.title}>
          <%= if qty(@line_item) > 0 do %>
            <div class="absolute top-6 right-6">
              <.button color="secondary" label={qty(@line_item)} phx-click="remove" phx-target={@myself} />
            </div>
          <% end %>
          <%= @product.description %>
        </.card_content>
        <.card_footer>
          <div class="flex w-full justify-between items-end">
            <.h2 class="mb-0">$<%= @product.price %></.h2>
            <div>
              <.button link_type="button" label="View" color="primary" phx-click="minus" phx-target={@myself}>
                <HeroiconsV1.Solid.minus class="w-4 h-6" />
              </.button>
              <.button link_type="button" label="View" color="primary" phx-click="add" phx-target={@myself}>
                <HeroiconsV1.Solid.plus class="w-4 h-6" />
              </.button>
            </div>
          </div>
        </.card_footer>
      </.card>
    </div>
    """
  end

  def qty(nil), do: 0
  def qty(line_item), do: line_item.qty

  @impl true
  def handle_event("remove", _, %{assigns: assigns} = socket) do
    %{cart: cart} = assigns
    case assigns do
      %{line_item: nil} -> nil
      %{line_item: line_item} -> Shop.decrease_qty_of_item_in_order(cart, line_item, line_item.qty)
    end

    {:noreply, socket}
  end

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
end
