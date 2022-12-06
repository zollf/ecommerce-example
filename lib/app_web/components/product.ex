defmodule AppWeb.Components.Product do
  use AppWeb, :live_component

  alias App.Models.Cart
  alias App.Models.LineItem

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def render(%{product: _, cart_id: _, session: _} = assigns) do
    ~H"""
    <div class="card">
      <div class="card-body">
        <h5 class="card-title">
          <%= @product.title %>
        </h5>
        <p class="card-text">
          <%= @product.description %>
          <div class="btn-group">
            <button type="button" class="btn btn-outline-secondary d-flex align-items-center" phx-click="minus" phx-target={@myself}>
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-dash-lg" viewBox="0 0 16 16">
                <path fill-rule="evenodd" d="M2 8a.5.5 0 0 1 .5-.5h11a.5.5 0 0 1 0 1h-11A.5.5 0 0 1 2 8Z"/>
              </svg>
            </button>
            <div class="btn d-flex align-items-center disabled">
              <%= quantity(@line_item) %>
            </div>
            <button type="button" class="btn btn-outline-secondary d-flex align-items-center" phx-click="add" phx-target={@myself}>
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-plus-lg" viewBox="0 0 16 16">
                <path fill-rule="evenodd" d="M8 2a.5.5 0 0 1 .5.5v5h5a.5.5 0 0 1 0 1h-5v5a.5.5 0 0 1-1 0v-5h-5a.5.5 0 0 1 0-1h5v-5A.5.5 0 0 1 8 2Z"/>
              </svg>
            </button>
          </div>
        </p>
      </div>
    </div>
    """
  end

  @impl true
  def preload(list_of_assigns) do
    list_of_product_ids = Enum.map(list_of_assigns, &(&1.product.id))
    cart_id = Enum.at(list_of_assigns, 0).cart_id
    line_items = Cart.get_product_line_items(cart_id, list_of_product_ids)
    Enum.map(list_of_assigns, fn assigns ->
      Map.put(assigns, :line_item, Enum.find(line_items, &(&1.product_id == assigns.product.id)))
    end)
  end

  def quantity(nil), do: 0
  def quantity(line_item), do: line_item.qty

  @impl true
  def handle_event("add", _, %{assigns: assigns} = socket) do
    %{product: product, session: session} = assigns
    case handle_add(assigns) do
      {:ok, line_item} -> broadcast(session, {:updated_line_item, line_item, product})
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("minus", _, %{assigns: assigns} = socket) do
    %{session: session, product: product} = assigns
    case handle_minus(assigns) do
      {:ok, line_item} -> broadcast(session, {:updated_line_item, line_item, product})
    end

    {:noreply, socket}
  end

  defp handle_add(%{line_item: nil, product: product, cart_id: cart_id}), do: LineItem.create(%{cart: cart_id, product: product.id, qty: 1})
  defp handle_add(%{line_item: line_item}), do: LineItem.add_quantity(line_item)

  defp handle_minus(%{line_item: nil}), do: {:ok, nil}
  defp handle_minus(%{line_item: line_item}), do: LineItem.minus_quantity(line_item)

  defp broadcast(session, message) do
    Phoenix.PubSub.broadcast(App.PubSub, session, message)
  end
end
