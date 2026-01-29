defmodule PurseCraft.Repo.Migrations.CreateCqrsReadModels do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:new_users, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :email, :citext, null: false
      add :hashed_password, :string
      add :confirmed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:new_users, [:email])

    create table(:new_users_tokens, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :user_id, references(:new_users, type: :uuid, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      add :authenticated_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:new_users_tokens, [:user_id])
    create unique_index(:new_users_tokens, [:context, :token])
  end
end
