defmodule PurseCraft.Repo.Migrations.CreateSearchTokens do
  use Ecto.Migration

  def change do
    create table(:search_tokens) do
      add :entity_type, :string, null: false
      add :entity_id, :bigint, null: false
      add :field_name, :string, null: false
      add :token_hash, :binary, null: false
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false
      add :algorithm_version, :integer, null: false, default: 1
      add :token_length, :integer, null: false, default: 3

      timestamps(type: :utc_datetime)
    end

    create index(:search_tokens, [:workspace_id, :token_hash])
    create index(:search_tokens, [:entity_type, :entity_id])
    create index(:search_tokens, [:workspace_id, :entity_type, :token_hash])

    create unique_index(:search_tokens, [:entity_type, :entity_id, :field_name, :token_hash])
  end
end
