defmodule PurseCraft.Budgeting.Schemas.Book do
  @moduledoc """
  A `Book` represents the user's budget. This is also the
  umbrella table where everything about budgets are grouped
  under.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias PurseCraft.Budgeting.Schemas.BookUser
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Budgeting.Schemas.User

  @type t :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          name: String.t() | nil,
          external_id: Ecto.UUID.t() | nil,
          categories: [Category.t()] | Ecto.Association.NotLoaded.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type changeset_attrs :: %{
          optional(:name) => String.t()
        }

  schema "books" do
    field :external_id, Ecto.UUID, autogenerate: true
    field :name, :string

    many_to_many :users, User, join_through: BookUser
    has_many :books_users, BookUser
    has_many :categories, Category

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), changeset_attrs()) :: Ecto.Changeset.t()
  def changeset(book, attrs) do
    book
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
