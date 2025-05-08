defmodule PurseCraft.Repo.Migrations.CreateCategoriesAndEnvelopes do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name, :string, null: false
      add :external_id, :uuid, null: false
      add :book_id, references(:books, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:categories, [:book_id])
    create unique_index(:categories, [:external_id])

    create table(:envelopes) do
      add :name, :string, null: false
      add :external_id, :uuid, null: false
      add :category_id, references(:categories, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:envelopes, [:category_id])
    create unique_index(:envelopes, [:external_id])
  end
end
