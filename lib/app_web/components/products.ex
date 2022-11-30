defmodule AppWeb.Components.Products do
  use AppWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="row">
      <%= for product <- @products do %>
        <div class="col-sm-3">
          <div class="card">
            <div class="card-body">
              <h5 class="card-title">
                <%= product.title %>
              </h5>
              <p class="card-text">
                <%= product.description %>
              </p>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    session = assigns.session
    products = App.Models.Product.all()
    assigns = Map.merge(assigns, %{products: products})
    {:ok, assign(socket, assigns)}
  end
end
