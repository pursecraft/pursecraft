defmodule PurseCraft.Repo.Migrations.CreatePayees do
  use Ecto.Migration

  def change do
    create table(:payees) do
      add :external_id, :uuid, null: false

      add :name, :binary, null: false
      add :name_hash, :binary, null: false

      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:payees, [:external_id])
    create unique_index(:payees, [:name_hash, :workspace_id])
    create index(:payees, [:workspace_id])
  end
end
