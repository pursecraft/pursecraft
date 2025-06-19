defmodule PurseCraft.Accounting.Repositories.AccountRepository do
  @moduledoc """
  Repository for `Account`.
  """

  alias PurseCraft.Accounting.Queries.AccountQuery
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Repo
  alias PurseCraft.Types

  @type get_option :: {:preload, Types.preload()} | {:active_only, boolean()}
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

  @doc """
  Gets an account by external ID for a specific book.

  ## Options

  - `:preload` - Associations to preload (default: [])
  - `:active_only` - Filter to only active (non-closed) accounts (default: true)

  ## Examples

      iex> get_by_external_id(1, "uuid-123")
      %Account{}

      iex> get_by_external_id(1, "invalid-uuid")
      nil

      iex> get_by_external_id(1, "uuid-123", preload: [:book], active_only: true)
      %Account{book: %Book{}}

  """
  @spec get_by_external_id(integer(), String.t(), get_options()) :: Account.t() | nil
  def get_by_external_id(book_id, external_id, opts \\ []) do
    book_id
    |> AccountQuery.by_book_id()
    |> AccountQuery.by_external_id(external_id)
    |> maybe_active_only(opts)
    |> Repo.one()
    |> maybe_preload(opts)
  end

  defp maybe_active_only(query, opts) do
    if Keyword.get(opts, :active_only, true) do
      AccountQuery.active(query)
    else
      query
    end
  end

  defp maybe_preload(nil, _opts), do: nil

  defp maybe_preload(account, opts) do
    case Keyword.get(opts, :preload, []) do
      [] -> account
      preload_opts -> Repo.preload(account, preload_opts)
    end
  end
end
