defmodule AppWeb.Components.Product do
  use AppWeb, :live_component

  alias App.Models.Cart

  alias App.Schema

  @type assign :: %{
    line_item: nil | Schema.LineItem,
    product: Schema.Product,
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
    <.card class="max-w-sm" variant="outline">
      <.card_content category="Article" class="max-w-sm" heading="Enhance your Phoenix development">
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus eget leo interdum, feugiat ligula eu, facilisis massa. Nunc sollicitudin massa a elit laoreet.
      </.card_content>
      <.card_footer>
        <.button to="/" label="View">
          <HeroiconsV1.Solid.eye class="w-4 h-4 mr-2" />View
        </.button>
      </.card_footer>
    </.card>
    <div class="card">
      <div class="card-body">
        <h5 class="card-title">
          <%= @product.title %>
        </h5>
        <p class="card-text">
          <%= @product.description %>
          <div class="d-flex justify-content-between">
            <div class="btn-group">
              <button type="button" class="btn btn-outline-secondary d-flex align-items-center" phx-click="minus" phx-target={@myself}>
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-dash-lg" viewBox="0 0 16 16">
                  <path fill-rule="evenodd" d="M2 8a.5.5 0 0 1 .5-.5h11a.5.5 0 0 1 0 1h-11A.5.5 0 0 1 2 8Z"/>
                </svg>
              </button>
              <div class="btn d-flex align-items-center disabled">
                <%= qty(@line_item) %>
              </div>
              <button type="button" class="btn btn-outline-secondary d-flex align-items-center" phx-click="add" phx-target={@myself}>
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-plus-lg" viewBox="0 0 16 16">
                  <path fill-rule="evenodd" d="M8 2a.5.5 0 0 1 .5.5v5h5a.5.5 0 0 1 0 1h-5v5a.5.5 0 0 1-1 0v-5h-5a.5.5 0 0 1 0-1h5v-5A.5.5 0 0 1 8 2Z"/>
                </svg>
              </button>
            </div>
            <div>
              <%= @product.price %>
            </div>
          </div>
        </p>
      </div>
    </div>
    </div>
    """
  end

  def qty(nil), do: 0
  def qty(line_item), do: line_item.qty

  @impl true
  def handle_event("add", _, %{assigns: assigns} = socket) do
    %{product: product, cart: cart} = assigns
    case assigns do
      %{line_item: nil} -> Cart.increase_qty(cart, product)
      %{line_item: line_item} -> Cart.increase_qty(cart, line_item)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("minus", _, %{assigns: assigns} = socket) do
    %{cart: cart} = assigns
    case assigns do
      %{line_item: nil} -> nil
      %{line_item: line_item} -> Cart.decrease_qty(cart, line_item)
    end
    {:noreply, socket}
  end
end
