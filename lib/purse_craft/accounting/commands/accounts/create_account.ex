defmodule PurseCraft.Accounting.Commands.Accounts.CreateAccount do
  @moduledoc """
  Creates an account and associates it with the given `Book`.
  """

  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Core.Schemas.Book
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub
  alias PurseCraft.Utilities
  alias PurseCraft.Utilities.FractionalIndexing

  @type create_attrs :: %{
          optional(:name) => String.t(),
          optional(:account_type) => String.t(),
          optional(:description) => String.t()
        }

  @doc """
  Creates an account and associates it with the given `Book`.

  ## Examples

      iex> call(authorized_scope, book, %{name: "Checking Account", account_type: "checking"})
      {:ok, %Account{}}

      iex> call(authorized_scope, book, %{name: "", account_type: "invalid"})
      {:error, %Ecto.Changeset{}}

      iex> call(unauthorized_scope, book, %{name: "Checking Account", account_type: "checking"})
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Book.t(), create_attrs()) ::
          {:ok, Account.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized} | {:error, :cannot_place_at_top}
  def call(%Scope{} = scope, %Book{} = book, attrs \\ %{}) do
    with :ok <- Policy.authorize(:account_create, scope, %{book: book}),
         first_position = AccountRepository.get_first_position(book.id),
         {:ok, position} <- generate_top_position(first_position),
         attrs = build_attrs(attrs, book.id, position),
         {:ok, account} <- AccountRepository.create(attrs) do
      PubSub.broadcast_book(book, {:account_created, account})
      {:ok, account}
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
