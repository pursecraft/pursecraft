defmodule PurseCraft.Repo.Migrations.CreateWorkspaces do
  use Ecto.Migration

  def change do
    create table(:workspaces) do
      add :external_id, :uuid, null: false
      add :name, :binary, null: false
      add :name_hash, :binary, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:workspaces, [:external_id])
  end
end
