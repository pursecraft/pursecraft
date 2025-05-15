defmodule PurseCraft.Repo.Migrations.AddPositionToCategoriesAndEnvelopes do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      add :position, :integer, default: 0, null: false
    end

    alter table(:envelopes) do
      add :position, :integer, default: 0, null: false
    end

    # Create index on position fields for efficient ordering
    create index(:categories, [:book_id, :position])
    create index(:envelopes, [:category_id, :position])
  end
end
