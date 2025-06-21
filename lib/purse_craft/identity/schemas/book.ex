defmodule PurseCraft.Identity.Schemas.Book do
  @moduledoc """
  A `Book` represents the user's budget. This is also the
  umbrella table where everything about budgets are grouped
  under.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias PurseCraft.Identity.Schemas.BookUser
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Identity.Schemas.User
  alias PurseCraft.Utilities.EncryptedBinary
  alias PurseCraft.Utilities.HashedHMAC

  @type t :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          name: String.t() | nil,
          name_hash: binary() | nil,
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
    field :name, EncryptedBinary
    field :name_hash, HashedHMAC

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
    |> put_hashed_fields()
    |> validate_required([:name])
  end

  defp put_hashed_fields(changeset) do
    case get_field(changeset, :name) do
      nil ->
        changeset

      name when is_binary(name) ->
        put_change(changeset, :name_hash, name)

      _other ->
        # coveralls-ignore-next-line
        changeset
    end
  end
end
