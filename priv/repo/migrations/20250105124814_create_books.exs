defmodule PurseCraft.Repo.Migrations.CreateBooks do
  use Ecto.Migration

  def change do
    create table(:books) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
