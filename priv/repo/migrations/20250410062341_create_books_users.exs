defmodule PurseCraft.Repo.Migrations.CreateBooksUsers do
  use Ecto.Migration

  def change do
    create table(:books_users) do
      add :role, :string
      add :book_id, references(:books, type: :id, on_delete: :delete_all)
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:books_users, [:book_id, :user_id])
    create index(:books_users, [:user_id])
  end
end
