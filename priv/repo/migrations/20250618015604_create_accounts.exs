defmodule PurseCraft.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :external_id, :binary_id, null: false
      add :name, :binary, null: false
      add :name_hash, :binary, null: false
      add :account_type, :binary, null: false
      add :account_type_hash, :binary, null: false
      add :description, :binary
      add :description_hash, :binary
      add :position, :string, null: false
      add :book_id, references(:books, on_delete: :delete_all), null: false
      add :closed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:accounts, [:external_id])
    create index(:accounts, [:book_id])
    create index(:accounts, [:account_type_hash])
    create index(:accounts, [:position])
    create index(:accounts, [:name_hash])
    create index(:accounts, [:closed_at])
  end
end
