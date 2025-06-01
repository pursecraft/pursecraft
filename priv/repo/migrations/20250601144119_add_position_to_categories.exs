defmodule PurseCraft.Repo.Migrations.AddPositionToCategories do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      add :position, :string, null: false
    end

    create unique_index(:categories, [:book_id, :position])
  end
end
