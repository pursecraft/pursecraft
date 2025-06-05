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
  alias PurseCraft.Utilities.FractionalIndexing

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
          {:ok, Category.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized} | {:error, :cannot_place_at_top}
  def call(%Scope{} = scope, %Book{} = book, attrs \\ %{}) do
    with :ok <- Policy.authorize(:category_create, scope, %{book: book}),
         first_position = CategoryRepository.get_first_position(book.id),
         {:ok, position} <- generate_top_position(first_position),
         attrs = build_attrs(attrs, book.id, position),
         {:ok, category} <- CategoryRepository.create(attrs) do
      BroadcastBook.call(book, {:category_created, category})
      {:ok, category}
    end
  end

  defp generate_top_position(first_position) do
    case FractionalIndexing.between(nil, first_position) do
      {:ok, position} -> {:ok, position}
      {:error, :cannot_go_before_a} -> {:error, :cannot_place_at_top}
    end
  end

  defp build_attrs(attrs, book_id, position) do
    attrs
    |> Utilities.atomize_keys()
    |> Map.put(:book_id, book_id)
    |> Map.put(:position, position)
  end
end
