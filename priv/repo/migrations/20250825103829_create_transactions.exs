defmodule PurseCraft.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :external_id, :uuid, null: false

      add :date, :date, null: false
      add :amount, :bigint, default: 0, null: false

      add :memo, :binary
      add :memo_hash, :binary

      add :account_id, references(:accounts, on_delete: :restrict), null: false
      add :payee_id, references(:payees, on_delete: :restrict)
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false

      add :linked_transaction_id, references(:transactions, on_delete: :nilify_all)

      add :cleared, :boolean, default: false, null: false
      add :reconciled_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:transactions, [:external_id])
    create index(:transactions, [:workspace_id])
    create index(:transactions, [:account_id])
    create index(:transactions, [:payee_id])
    create index(:transactions, [:linked_transaction_id])
    create index(:transactions, [:date])
    create index(:transactions, [:cleared])
    create index(:transactions, [:reconciled_at])
  end
end
