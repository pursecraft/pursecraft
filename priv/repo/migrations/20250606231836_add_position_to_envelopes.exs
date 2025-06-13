defmodule PurseCraft.Repo.Migrations.AddPositionToEnvelopes do
  use Ecto.Migration

  def change do
    alter table(:envelopes) do
      add :position, :string, null: false
    end

    create unique_index(:envelopes, [:category_id, :position])
  end
end
