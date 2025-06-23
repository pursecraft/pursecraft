defmodule PurseCraft.Budgeting.Commands.Categories.FetchCategoryByExternalId do
  @moduledoc """
  Fetches a category by external ID for a given book.
  """

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.CategoryRepository
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Types
  alias PurseCraft.Utilities

  @type option :: {:preload, Types.preload()}
  @type options :: [option()]

  @doc """
  Fetches a category by external ID for a given book.

  ## Examples

      iex> call(authorized_scope, book, "abcd-1234", preload: [:envelopes])
      {:ok, %Category{envelopes: [%Envelope{}, ...]}}

      iex> call(authorized_scope, book, "invalid-id")
      {:error, :not_found}

      iex> call(unauthorized_scope, book, "abcd-1234")
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Book.t(), Ecto.UUID.t(), options()) ::
          {:ok, Category.t()} | {:error, :not_found | :unauthorized}
  def call(%Scope{} = scope, %Book{} = book, external_id, opts \\ []) do
    with :ok <- Policy.authorize(:category_read, scope, %{book: book}) do
      external_id
      |> CategoryRepository.get_by_external_id_and_book_id(book.id, opts)
      |> Utilities.to_result()
    end
  end
end
