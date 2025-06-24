defmodule PurseCraft.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :external_id, :uuid, null: false
      add :name, :binary, null: false
      add :name_hash, :binary, null: false
      add :account_type, :binary, null: false
      add :account_type_hash, :binary, null: false
      add :description, :binary
      add :description_hash, :binary
      add :book_id, references(:books, on_delete: :delete_all), null: false
      add :position, :string, null: false
      add :closed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:accounts, [:external_id])
    create unique_index(:accounts, [:book_id, :position])
    create index(:accounts, [:account_type_hash])
  end
end
