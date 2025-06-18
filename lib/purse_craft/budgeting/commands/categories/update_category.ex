defmodule PurseCraft.Budgeting.Commands.Categories.UpdateCategory do
  @moduledoc """
  Updates a category with the given attributes.
  """

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.CategoryRepository
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub.BroadcastBook
  alias PurseCraft.Types
  alias PurseCraft.Utilities

  @type attrs :: %{
          optional(:name) => String.t()
        }

  @type option :: {:preload, Types.preload()}
  @type options :: [option()]

  @doc """
  Updates a category with the given attributes.

  ## Preloading options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[:envelopes]` - preloads only envelopes

  ## Examples

      iex> call(authorized_scope, book, category, %{name: "Updated Name"})
      {:ok, %Category{}}

      iex> call(authorized_scope, book, category, %{name: "Updated Name"}, preload: [:envelopes])
      {:ok, %Category{envelopes: [%Envelope{}, ...]}}

      iex> call(authorized_scope, book, category, %{name: ""})
      {:error, %Ecto.Changeset{}}

      iex> call(unauthorized_scope, book, category, %{name: "Updated Name"})
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Book.t(), Category.t(), attrs(), options()) ::
          {:ok, Category.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def call(%Scope{} = scope, %Book{} = book, %Category{} = category, attrs, opts \\ []) do
    attrs = Utilities.atomize_keys(attrs)

    with :ok <- Policy.authorize(:category_update, scope, %{book: book}),
         {:ok, category} <- CategoryRepository.update(category, attrs, opts) do
      BroadcastBook.call(book, {:category_updated, category})
      {:ok, category}
    end
  end
end
