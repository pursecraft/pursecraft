defmodule PurseCraft.Budgeting.Schemas.BookUser do
  @moduledoc """
  `BookUser` represents the relationship between a `Book` and a `User` (obviously).

  Both tables have a many-to-many relationship, so it makes sense that the `role`
  column should be located in this table because a user could be an owner in one
  book, but could be just a commenter on another.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Budgeting.Schemas.User

  schema "books_users" do
    field :role, Ecto.Enum, values: [:owner, :editor, :commenter]

    belongs_to :book, Book
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @required_attrs [:book_id, :user_id, :role]

  @doc false
  def changeset(book_user, attrs) do
    book_user
    |> cast(attrs, @required_attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint([:book_id, :user_id])
  end
end
