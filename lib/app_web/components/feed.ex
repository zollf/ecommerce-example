defmodule AppWeb.Components.Feed do
  use AppWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="row">
      <.table>
        <.tr>
          <.th>Live Feed</.th>
        </.tr>

        <%= for text <- @feed do %>
          <.tr>
            <.td>
              <%= text %>
            </.td>
          </.tr>
        <% end %>
      </.table>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    old_feed = Map.get(socket.assigns, :feed, [])
    new_feed = Map.get(assigns, :feed, [])
    {:ok, assign(socket, feed: Enum.slice(new_feed ++ old_feed, 0, 10))}
  end
end
