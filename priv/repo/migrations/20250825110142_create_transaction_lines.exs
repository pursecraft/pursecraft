defmodule PurseCraft.Repo.Migrations.CreateTransactionLines do
  use Ecto.Migration

  def change do
    create table(:transaction_lines) do
      add :external_id, :uuid, null: false

      add :amount, :bigint, default: 0, null: false

      add :memo, :binary
      add :memo_hash, :binary

      add :transaction_id, references(:transactions, on_delete: :delete_all), null: false
      add :envelope_id, references(:envelopes, on_delete: :restrict)
      add :payee_id, references(:payees, on_delete: :restrict)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:transaction_lines, [:external_id])
    create index(:transaction_lines, [:transaction_id])
    create index(:transaction_lines, [:envelope_id])
    create index(:transaction_lines, [:payee_id])
  end
end
