defmodule PurseCraft.Repo.Migrations.CreateBooks do
  use Ecto.Migration

  def change do
    create table(:books) do
      add :external_id, :uuid, null: false
      add :name, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:books, [:external_id])
  end
end
