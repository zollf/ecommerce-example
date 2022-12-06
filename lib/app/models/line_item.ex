defmodule App.Models.LineItem do
  use App.Models, schema: App.Schema.LineItem

  alias App.Schema

  def add_quantity(%{qty: qty} = line_item) do
    line_item
    |> Schema.LineItem.update_changeset(%{qty: min(99, qty + 1)})
    |> Repo.update()
  end

  def minus_quantity(%{qty: qty} = line_item) when qty - 1 <= 0 do
    Repo.delete(line_item)
    {:ok, nil}
  end

  def minus_quantity(%{qty: qty} = line_item) do
    line_item
    |> Schema.LineItem.update_changeset(%{qty: max(0, qty - 1)})
    |> Repo.update()
  end
end
