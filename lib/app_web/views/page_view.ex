defmodule AppWeb.Views.Index do
  use AppWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    session = session["session_uid"]
    {:ok, assign(socket, session: session)}
  end

  @impl true
  def render(assigns) do
    # IO.inspect(assigns)
    ~H"""
    <div>
      <.live_component module={AppWeb.Components.MyCart} session={assigns.session} id="my-cart" />
      <.live_component module={AppWeb.Components.Products} session={assigns.session} id="products" />
    </div>
    """
  end
end
