defmodule App.Repo.Migrations.Install do
  use Ecto.Migration

  def change do
    create table(:carts) do
      add :uid, :string, null: false
      add :session, :string, null: false
      add :paid_date, :naive_datetime

      timestamps()
    end

    create table(:products) do
      add :uid, :string, null: false
      add :title, :string, null: false
      add :sku, :string, null: false
      add :description, :string, null: false
      add :price, :float, null: false
      add :image, :string, null: false

      timestamps()
    end

    create table(:line_items) do
      add :uid, :string, null: false
      add :cart_id, references(:carts, on_delete: :delete_all), null: false
      add :product_id, references(:products, on_delete: :delete_all), null: false
      add :qty, :integer, null: false

      timestamps()
    end
  end
end
