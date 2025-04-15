defmodule PurseCraft.Budgeting.Schemas.Book do
  use Ecto.Schema
  import Ecto.Changeset

  alias PurseCraft.Budgeting.Schemas.BookUser
  alias PurseCraft.Budgeting.Schemas.User

  schema "books" do
    field :external_id, Ecto.UUID, autogenerate: true
    field :name, :string

    many_to_many :users, User, join_through: BookUser
    has_many :books_users, BookUser

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
