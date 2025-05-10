defmodule PurseCraft.Budgeting do
  @moduledoc """
  The Budgeting context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Budgeting.Schemas.BookUser
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Repo

  @type create_book_attrs :: %{
          optional(:name) => String.t()
        }

  @type update_book_attrs :: %{
          optional(:name) => String.t()
        }

  @type change_book_attrs :: %{
          optional(:name) => String.t()
        }

  @type create_category_attrs :: %{
          optional(:name) => String.t()
        }

  @type fetch_book_by_external_id_option :: {:preload, Keyword.t()}
  @type fetch_book_by_external_id_options :: [fetch_book_by_external_id_option()]

  @doc """
  Subscribes to notifications about any book changes associated with the scoped user.

  The broadcasted messages match the pattern:

    * {:created, %Book{}}
    * {:updated, %Book{}}
    * {:deleted, %Book{}}

  """
  @spec subscribe_user_books(Scope.t()) :: :ok | {:error, term()}
  def subscribe_user_books(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(PurseCraft.PubSub, "user:#{key}:books")
  end

  @doc """
  Sends notifications about any book changes associated with the scoped user.

  The broadcasted messages match the pattern:

    * {:created, %Book{}}
    * {:updated, %Book{}}
    * {:deleted, %Book{}}

  """
  @spec broadcast_user_book(Scope.t(), tuple()) :: :ok | {:error, term()}
  def broadcast_user_book(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(PurseCraft.PubSub, "user:#{key}:books", message)
  end

  @doc """
  Subscribes to notifications about any changes on the given book.

  The broadcasted messages match the pattern:

    * {:updated, %Book{}}
    * {:deleted, %Book{}}

  """
  @spec subscribe_book(Book.t()) :: :ok | {:error, term()}
  def subscribe_book(%Book{} = book) do
    Phoenix.PubSub.subscribe(PurseCraft.PubSub, "book:#{book.external_id}")
  end

  @doc """
  Sends notifications about any changes on the given book

  The broadcasted messages match the pattern:

    * {:updated, %Book{}}
    * {:deleted, %Book{}}

  """
  @spec broadcast_book(Book.t(), tuple()) :: :ok | {:error, term()}
  def broadcast_book(%Book{} = book, message) do
    Phoenix.PubSub.broadcast(PurseCraft.PubSub, "book:#{book.external_id}", message)
  end

  @doc """
  Returns the list of books.

  ## Examples

      iex> list_books(authorized_scope)
      [%Book{}, ...]

      iex> list_books(unauthorized_scope)
      {:error, :unauthorized}

  """
  @spec list_books(Scope.t()) :: list(Book.t()) | {:error, :unauthorized}
  def list_books(%Scope{} = scope) do
    with :ok <- Policy.authorize(:book_list, scope) do
      Book
      |> join(:inner, [b], bu in BookUser, on: bu.book_id == b.id)
      |> where([_b, bu], bu.user_id == ^scope.user.id)
      |> Repo.all()
    end
  end

  @doc """
  Gets a single `Book` by its `external_id`.

  Raises `LetMe.UnauthorizedError` if the given scope is not authorized to
  view the book.

  Raises `Ecto.NoResultsError` if the Book does not exist.

  ## Examples

      iex> get_book_by_external_id!(authorized_scope, abcd-1234)
      %Book{}

      iex> get_book_by_external_id!(unauthorized_scope, abcd-1234)
      ** (LetMe.UnauthorizedError)

  """
  @spec get_book_by_external_id!(Scope.t(), Ecto.UUID.t()) :: Book.t()
  def get_book_by_external_id!(%Scope{} = scope, external_id) do
    :ok = Policy.authorize!(:book_read, scope, %{book: %Book{external_id: external_id}})

    Repo.get_by!(Book, external_id: external_id)
  end

  @doc """
  Fetches a single `Book` by its `external_id` with optional preloading of associations.

  Returns a tuple of `{:ok, book}` if the book exists, or `{:error, :not_found}` if not found.
  Returns `{:error, :unauthorized}` if the given scope is not authorized to view the book.

  ## Preloading options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[:categories]` - preloads only categories
  - `[categories: :envelopes]` - preloads categories and their envelopes

  ## Examples

      iex> fetch_book_by_external_id(authorized_scope, "abcd-1234", preload: [categories: :envelopes])
      {:ok, %Book{categories: [%Category{envelopes: [%Envelope{}, ...]}]}}

      iex> fetch_book_by_external_id(authorized_scope, "invalid-id")
      {:error, :not_found}

      iex> fetch_book_by_external_id(unauthorized_scope, "abcd-1234")
      {:error, :unauthorized}

  """
  @spec fetch_book_by_external_id(Scope.t(), Ecto.UUID.t(), fetch_book_by_external_id_options()) ::
          {:ok, Book.t()} | {:error, :not_found | :unauthorized}
  def fetch_book_by_external_id(%Scope{} = scope, external_id, opts \\ []) do
    with :ok <- Policy.authorize(:book_read, scope, %{book: %Book{external_id: external_id}}) do
      case Repo.get_by(Book, external_id: external_id) do
        nil ->
          {:error, :not_found}

        book ->
          preloads = Keyword.get(opts, :preload, [])
          {:ok, Repo.preload(book, preloads)}
      end
    end
  end

  @doc """
  Creates a book.

  ## Examples

      iex> create_book(authorized_scope, %{field: value})
      {:ok, %Book{}}

      iex> create_book(authorized_scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> create_book(unauthorized_scope, %{field: value})
      {:error, :unauthorized}

  """
  @spec create_book(Scope.t(), create_book_attrs()) ::
          {:ok, Book.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def create_book(%Scope{} = scope, attrs \\ %{}) do
    with :ok <- Policy.authorize(:book_create, scope) do
      Multi.new()
      |> Multi.insert(:book, Book.changeset(%Book{}, attrs))
      |> Multi.insert(:book_user, fn %{book: book} ->
        BookUser.changeset(%BookUser{}, %{
          book_id: book.id,
          user_id: scope.user.id,
          role: :owner
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{book: book}} ->
          broadcast_user_book(scope, {:created, book})
          {:ok, book}

        {:error, _operations, changeset, _changes} ->
          {:error, changeset}
      end
    end
  end

  @doc """
  Updates a book.

  ## Examples

      iex> update_book(authorized_scope, book, %{field: new_value})
      {:ok, %Book{}}

      iex> update_book(authorized_scope, book, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> update_book(unauthorized_scope, book, %{field: new_value})
      {:error, :unauthorized}

  """
  @spec update_book(Scope.t(), Book.t(), update_book_attrs()) ::
          {:ok, Book.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def update_book(%Scope{} = scope, %Book{} = book, attrs) do
    with :ok <- Policy.authorize(:book_update, scope, %{book: book}),
         {:ok, %Book{} = book} <-
           book
           |> Book.changeset(attrs)
           |> Repo.update() do
      message = {:updated, book}

      broadcast_user_book(scope, message)
      broadcast_book(book, message)

      {:ok, book}
    end
  end

  @doc """
  Deletes a book.

  ## Examples

      iex> delete_book(authorized_scope, book)
      {:ok, %Book{}}

      iex> delete_book(authorized_scope, book)
      {:error, :unauthorized}

  """
  @spec delete_book(Scope.t(), Book.t()) :: {:ok, Book.t()} | {:error, :unauthorized}
  def delete_book(%Scope{} = scope, %Book{} = book) do
    with :ok <- Policy.authorize(:book_delete, scope, %{book: book}),
         {:ok, %Book{} = book} <-
           Repo.delete(book) do
      message = {:deleted, book}

      broadcast_user_book(scope, message)
      broadcast_book(book, message)

      {:ok, book}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking book changes.

  ## Examples

      iex> change_book(book)
      %Ecto.Changeset{data: %Book{}}

  """
  @spec change_book(Book.t(), change_book_attrs()) :: Ecto.Changeset.t()
  def change_book(%Book{} = book, attrs \\ %{}) do
    Book.changeset(book, attrs)
  end

  @doc """
  Creates a category for a book.

  ## Examples

      iex> create_category(authorized_scope, book, %{field: value})
      {:ok, %Category{}}

      iex> create_category(authorized_scope, book, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> create_category(unauthorized_scope, book, %{field: value})
      {:error, :unauthorized}

  """
  @spec create_category(Scope.t(), Book.t(), create_category_attrs()) ::
          {:ok, Category.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def create_category(%Scope{} = scope, %Book{} = book, attrs \\ %{}) do
    with :ok <- Policy.authorize(:category_create, scope, %{book: book}) do
      attrs = Map.put(attrs, :book_id, book.id)

      %Category{}
      |> Category.changeset(attrs)
      |> Repo.insert()
      |> case do
        {:ok, category} ->
          broadcast_book(book, {:category_created, category})
          {:ok, category}

        error ->
          error
      end
    end
  end
end
