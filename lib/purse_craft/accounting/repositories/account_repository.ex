defmodule PurseCraft.Accounting.Repositories.AccountRepository do
  @moduledoc """
  Repository for `Account`.
  """

  alias PurseCraft.Accounting.Queries.AccountQuery
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Repo
  alias PurseCraft.Types

  @type get_option :: {:preload, Types.preload()}
  @type get_options :: [get_option()]

  @type list_option :: {:preload, Types.preload()}
  @type list_options :: [list_option()]

  @type create_attrs :: %{
          optional(:name) => String.t(),
          optional(:description) => String.t(),
          required(:account_type) => String.t(),
          required(:book_id) => integer(),
          required(:position) => String.t()
        }

  @doc """
  Creates an account for a book.

  ## Examples

      iex> create(%{name: "My Checking", account_type: :checking, book_id: 1, position: "m"})
      {:ok, %Account{}}

      iex> create(%{name: "", account_type: :checking, book_id: 1, position: "m"})
      {:error, %Ecto.Changeset{}}

  """
  @spec create(create_attrs()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Account{}
    |> Account.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets the position of the first account in a book (ordered by position).

  Returns the position as a string, or nil if no accounts exist.

  ## Examples

      iex> get_first_position(1)
      "g"

      iex> get_first_position(999)
      nil

  """
  @spec get_first_position(integer()) :: String.t() | nil
  def get_first_position(book_id) do
    book_id
    |> AccountQuery.by_book_id()
    |> AccountQuery.order_by_position()
    |> AccountQuery.limit(1)
    |> AccountQuery.select_position()
    |> Repo.one()
  end
end
