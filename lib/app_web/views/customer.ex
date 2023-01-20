defmodule AppWeb.Views.Customer do
  use AppWeb, :view

  alias App.Shop.Customer
  alias AppWeb.Views

  def render("view.json", %{customer: %Customer{} = customer}) do
    %{data: render_one(customer, Views.Customer, "customer.json", as: :customer)}
  end

  def render("customer.json", %{customer: %Customer{} = customer}) do
    %{
      id: customer.id,
      name: customer.name,
      uid: customer.uid,
      inserted_at: customer.inserted_at,
      updated_at: customer.updated_at
    }
  end
end
