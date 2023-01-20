defmodule App.Repo.Migrations.Install do
  use Ecto.Migration

  def change do
    create table(:customers) do
      add :session_uid, :string, null: false
      add :uid, :string, null: false
      add :name, :string

      timestamps()
    end

    create table(:orders) do
      add :uid, :string, null: false
      add :paid_date, :naive_datetime
      add :customer_id, references(:customers), null: false

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
      add :order_id, references(:orders, on_delete: :delete_all), null: false
      add :product_id, references(:products), null: false
      add :qty, :integer, null: false

      timestamps()
    end
  end
end
