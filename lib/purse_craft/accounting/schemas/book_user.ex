defmodule PurseCraft.Accounting.Schemas.BookUser do
  @moduledoc """
  `BookUser` represents the relationship between an accounting `Book` and a `User`.

  Both tables have a many-to-many relationship, so it makes sense that the `role`
  column should be located in this table because a user could be an owner in one
  book, but could be just a commenter on another.

  This schema references the same `books_users` table as the budgeting context
  but provides accounting domain-specific associations.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias PurseCraft.Accounting.Schemas.Book
  alias PurseCraft.Accounting.Schemas.User

  @type t :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          role: atom() | nil,
          book_id: integer() | nil,
          user_id: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type changeset_attrs :: %{
          book_id: integer(),
          user_id: integer(),
          role: atom()
        }

  schema "books_users" do
    field :role, Ecto.Enum, values: [:owner, :editor, :commenter]

    belongs_to :book, Book
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @required_attrs [:book_id, :user_id, :role]

  @doc false
  @spec changeset(t(), changeset_attrs()) :: Ecto.Changeset.t()
  def changeset(book_user, attrs) do
    book_user
    |> cast(attrs, @required_attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint([:book_id, :user_id])
  end
end
