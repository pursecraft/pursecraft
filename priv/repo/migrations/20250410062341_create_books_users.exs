defmodule PurseCraft.Repo.Migrations.CreateWorkspacesUsers do
  use Ecto.Migration

  def change do
    create table(:workspaces_users) do
      add :role, :string
      add :workspace_id, references(:workspaces, type: :id, on_delete: :delete_all)
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:workspaces_users, [:workspace_id, :user_id])
    create index(:workspaces_users, [:user_id])
  end
end
