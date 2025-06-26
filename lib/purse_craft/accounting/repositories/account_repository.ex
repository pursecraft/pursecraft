defmodule PurseCraft.Accounting.Repositories.AccountRepository do
  @moduledoc """
  Repository for `Account`.
  """

  alias PurseCraft.Accounting.Queries.AccountQuery
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Repo
  alias PurseCraft.Types
  alias PurseCraft.Utilities

  @type create_attrs :: %{
          optional(:name) => String.t(),
          optional(:account_type) => String.t(),
          optional(:description) => String.t(),
          required(:book_id) => integer(),
          required(:position) => String.t()
        }

  @type get_option :: {:preload, Types.preload()} | {:active_only, boolean()}
  @type get_options :: [get_option()]

  @doc """
  Creates an account for a book.

  ## Examples

      iex> create(%{name: "Checking Account", account_type: "checking", book_id: 1, position: "m"})
      {:ok, %Account{}}

      iex> create(%{name: "", account_type: "invalid", book_id: 1, position: "m"})
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
  Gets an account by external ID.

  ## Options

  * `:preload` - List of associations to preload. Defaults to `[]`.
  * `:active_only` - Whether to only return active accounts (not closed). Defaults to `true`.

  ## Examples

      iex> get_by_external_id("account-uuid")
      %Account{}

      iex> get_by_external_id("account-uuid", preload: [:book])
      %Account{book: %Book{}}

      iex> get_by_external_id("account-uuid", active_only: false)
      %Account{}

      iex> get_by_external_id("invalid-uuid")
      nil

  """
  @spec get_by_external_id(String.t(), get_options()) :: Account.t() | nil
  def get_by_external_id(external_id, opts \\ []) do
    external_id
    |> AccountQuery.by_external_id()
    |> maybe_active_only(opts)
    |> Repo.one()
    |> Utilities.maybe_preload(opts)
  end

  defp maybe_active_only(query, opts) do
    if Keyword.get(opts, :active_only, true) do
      AccountQuery.active(query)
    else
      query
    end
  end
end
