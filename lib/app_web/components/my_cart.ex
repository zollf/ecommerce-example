defmodule AppWeb.Components.MyCart do
  use AppWeb, :live_component

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
    {:ok, assign(socket, assigns)}
  end
end
