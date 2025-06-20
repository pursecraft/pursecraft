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

  @type list_option :: {:preload, Types.preload()} | {:active_only, boolean()}
  @type list_options :: [list_option()]

  @type create_attrs :: %{
          optional(:name) => String.t(),
          optional(:description) => String.t(),
          required(:account_type) => String.t(),
          required(:book_id) => integer(),
          required(:position) => String.t()
        }

  @type update_attrs :: %{
          optional(:name) => String.t(),
          optional(:description) => String.t()
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
  Updates an existing account.

  ## Examples

      iex> update(account, %{name: "Updated Name"})
      {:ok, %Account{}}

      iex> update(account, %{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  @spec update(Account.t(), update_attrs()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def update(account, attrs) do
    account
    |> Account.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Closes an account (business closure with closed_at timestamp).

  ## Examples

      iex> close(account)
      {:ok, %Account{}}

      iex> close(invalid_account)
      {:error, %Ecto.Changeset{}}

  """
  @spec close(Account.t()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def close(account) do
    account
    |> Account.close_changeset(%{closed_at: DateTime.utc_now()})
    |> Repo.update()
  end

  @doc """
  Deletes an account (hard delete).

  ## Examples

      iex> delete(account)
      {:ok, %Account{}}

      iex> delete(invalid_account)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete(Account.t()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def delete(account) do
    Repo.delete(account)
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

  defp maybe_preload(data, opts) do
    case Keyword.get(opts, :preload, []) do
      [] -> data
      preload_opts -> Repo.preload(data, preload_opts)
    end
  end

  @doc """
  Lists all accounts for a specific book, ordered by position.

  ## Options

  - `:preload` - Associations to preload (default: [])
  - `:active_only` - Filter to only active (non-closed) accounts (default: true)

  ## Examples

      iex> list_by_book(1)
      [%Account{}, %Account{}]

      iex> list_by_book(1, preload: [:book])
      [%Account{book: %Book{}}, %Account{book: %Book{}}]

      iex> list_by_book(1, active_only: false)
      [%Account{}, %Account{closed_at: ~U[2023-01-01 00:00:00Z]}]

  """
  @spec list_by_book(integer(), list_options()) :: [Account.t()]
  def list_by_book(book_id, opts \\ []) do
    book_id
    |> AccountQuery.by_book_id()
    |> maybe_active_only(opts)
    |> AccountQuery.order_by_position()
    |> Repo.all()
    |> maybe_preload(opts)
  end
end
