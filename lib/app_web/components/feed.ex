defmodule AppWeb.Components.Feed do
  use AppWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="row">
      <h2>Live Feed</h2>
      <%= for text <- @feed do %>
        <div class="row">
          <div>
            <%= text %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    old_feed = Map.get(socket.assigns, :feed, [])
    new_feed = Map.get(assigns, :feed, [])

    {:ok, assign(socket, feed: Enum.slice(new_feed ++ old_feed, 0, 5))}
  end
end
