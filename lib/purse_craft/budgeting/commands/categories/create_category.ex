defmodule PurseCraft.Budgeting.Commands.Categories.CreateCategory do
  @moduledoc """
  Creates a category and associates it with the given `Book`.
  """

  alias PurseCraft.Budgeting.Commands.PubSub.BroadcastBook
  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.CategoryRepository
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Utilities

  @type create_attrs :: %{
          optional(:name) => String.t()
        }

  @doc """
  Creates a category and associates it with the given `Book`.

  ## Examples

      iex> call(authorized_scope, book, %{name: "Monthly Bills"})
      {:ok, %Category{}}

      iex> call(authorized_scope, book, %{name: ""})
      {:error, %Ecto.Changeset{}}

      iex> call(unauthorized_scope, book, %{name: "Monthly Bills"})
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Book.t(), create_attrs()) ::
          {:ok, Category.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def call(%Scope{} = scope, %Book{} = book, attrs \\ %{}) do
    with :ok <- Policy.authorize(:category_create, scope, %{book: book}) do
      attrs =
        attrs
        |> Utilities.atomize_keys()
        |> Map.put(:book_id, book.id)

      case CategoryRepository.create(attrs) do
        {:ok, category} ->
          BroadcastBook.call(book, {:category_created, category})
          {:ok, category}

        error ->
          error
      end
    end
  end
end
