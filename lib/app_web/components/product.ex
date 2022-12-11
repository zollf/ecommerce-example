defmodule AppWeb.Components.Product do
  use AppWeb, :live_component

  import Ecto.Query

  alias App.Models.Cart

  alias App.Repo
  alias App.Schema
  alias App.Schema.LineItem

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
    """
  end

  @doc """
  We need to preload all line items as this component is responsible for state.
  First, we get all product ids, then query for all line items with matching product ids.
  Then we add line_item into the list of assigns in the correct order.
  This ensures each product has it's matching line_item if available.

  During the life cycle of this component, line_item can get added via `send_update`.
  This will cause `preload` to run again, during this we check if line_item is already loaded.
  This avoids an unnecessary query for information already known.
  """
  @impl true
  def preload(list_of_assigns) do
    product_ids_of_line_items = list_of_assigns
      |> Enum.filter(& !Map.get(&1, :line_item))
      |> Enum.map(& &1.product.id)

    existing_line_items = list_of_assigns
      |> Enum.filter(& !!Map.get(&1, :line_item))
      |> Enum.map(& &1.line_item)

    # cart id is the same for all assigns
    cart_id = Enum.at(list_of_assigns, 0).cart.id

    # If there are no line items to search for with product ids.
    # We can return immediately
    if Enum.empty?(product_ids_of_line_items) do
      list_of_assigns
    else
      line_items = Repo.all(
        from l in LineItem,
        where: l.product_id in ^product_ids_of_line_items and l.cart_id == ^cart_id
      )

      # <product id, line item> map
      all_line_items = line_items ++ existing_line_items
      |> Enum.map(& {&1.product_id, &1})
      |> Map.new

      # Reorder to initial list_of_assigns order
      list_of_assigns
      |> Enum.map(& Map.put(&1, :line_item, Map.get(all_line_items, &1.product.id)))
    end
  end

  def qty(nil), do: 0
  def qty(line_item), do: line_item.qty

  @impl true
  def handle_event("add", _, %{assigns: assigns} = socket) do
    %{product: product, cart: cart} = assigns
    case assigns do
      %{line_item: nil} -> Cart.add_product(cart, product)
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
