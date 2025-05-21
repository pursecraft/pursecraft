defmodule PurseCraft.Budgeting do
  @moduledoc """
  The Budgeting context.
  """

  import Ecto.Query, warn: false

  alias PurseCraft.Budgeting.Commands.Books.ChangeBook
  alias PurseCraft.Budgeting.Commands.Books.CreateBook
  alias PurseCraft.Budgeting.Commands.Books.DeleteBook
  alias PurseCraft.Budgeting.Commands.Books.FetchBookByExternalId
  alias PurseCraft.Budgeting.Commands.Books.GetBookByExternalId
  alias PurseCraft.Budgeting.Commands.Books.ListBooks
  alias PurseCraft.Budgeting.Commands.Books.UpdateBook
  alias PurseCraft.Budgeting.Commands.Categories.CreateCategory
  alias PurseCraft.Budgeting.Commands.PubSub.BroadcastBook
  alias PurseCraft.Budgeting.Commands.PubSub.BroadcastUserBook
  alias PurseCraft.Budgeting.Commands.PubSub.SubscribeBook
  alias PurseCraft.Budgeting.Commands.PubSub.SubscribeUserBooks
  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.BookRepository
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Repo
  alias PurseCraft.Utilities

  @type preload_item :: atom() | {atom(), preload_item()} | [preload_item()]
  @type preload :: preload_item() | [preload_item()]

  @type create_book_attrs :: %{
          optional(:name) => String.t()
        }

  @type update_book_attrs :: %{
          optional(:name) => String.t()
        }

  @type change_book_attrs :: %{
          optional(:name) => String.t()
        }

  @type fetch_category_by_external_id_option :: {:preload, preload()}
  @type fetch_category_by_external_id_options :: [fetch_category_by_external_id_option()]

  @type list_categories_option :: {:preload, preload()}
  @type list_categories_options :: [list_categories_option()]

  @type update_category_attrs :: %{
          optional(:name) => String.t()
        }

  @type update_category_option :: {:preload, preload()}
  @type update_category_options :: [update_category_option()]

  @type create_envelope_attrs :: %{
          optional(:name) => String.t()
        }

  @type update_envelope_attrs :: %{
          optional(:name) => String.t()
        }

  @type fetch_envelope_by_external_id_option :: {:preload, preload()}
  @type fetch_envelope_by_external_id_options :: [fetch_envelope_by_external_id_option()]

  @doc """
  Subscribes to notifications about any book changes associated with the scoped user.

  The broadcasted messages match the pattern:

    * {:created, %Book{}}
    * {:updated, %Book{}}
    * {:deleted, %Book{}}

  """
  @spec subscribe_user_books(Scope.t()) :: :ok | {:error, term()}
  defdelegate subscribe_user_books(scope), to: SubscribeUserBooks, as: :call

  @doc """
  Sends notifications about any book changes associated with the scoped user.

  The broadcasted messages match the pattern:

    * {:created, %Book{}}
    * {:updated, %Book{}}
    * {:deleted, %Book{}}

  """
  @spec broadcast_user_book(Scope.t(), tuple()) :: :ok | {:error, term()}
  defdelegate broadcast_user_book(scope, message), to: BroadcastUserBook, as: :call

  @doc """
  Subscribes to notifications about any changes on the given book.

  The broadcasted messages match the pattern:

    * {:updated, %Book{}}
    * {:deleted, %Book{}}

  """
  @spec subscribe_book(Book.t()) :: :ok | {:error, term()}
  defdelegate subscribe_book(book), to: SubscribeBook, as: :call

  @doc """
  Sends notifications about any changes on the given book

  The broadcasted messages match the pattern:

    * {:updated, %Book{}}
    * {:deleted, %Book{}}

  """
  @spec broadcast_book(Book.t(), tuple()) :: :ok | {:error, term()}
  defdelegate broadcast_book(book, message), to: BroadcastBook, as: :call

  @doc """
  Returns the list of books.

  ## Examples

      iex> list_books(authorized_scope)
      [%Book{}, ...]

      iex> list_books(unauthorized_scope)
      {:error, :unauthorized}

  """
  @spec list_books(Scope.t()) :: list(Book.t()) | {:error, :unauthorized}
  defdelegate list_books(scope), to: ListBooks, as: :call

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
  defdelegate get_book_by_external_id!(scope, external_id), to: GetBookByExternalId, as: :call!

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
  @spec fetch_book_by_external_id(Scope.t(), Ecto.UUID.t(), BookRepository.get_book_options()) ::
          {:ok, Book.t()} | {:error, :not_found | :unauthorized}
  defdelegate fetch_book_by_external_id(scope, external_id, opts \\ []), to: FetchBookByExternalId, as: :call

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
  @spec create_book(Scope.t(), BookRepository.create_attrs()) ::
          {:ok, Book.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  defdelegate create_book(scope, attrs \\ %{}), to: CreateBook, as: :call

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
  @spec update_book(Scope.t(), Book.t(), BookRepository.update_attrs()) ::
          {:ok, Book.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  defdelegate update_book(scope, book, attrs), to: UpdateBook, as: :call

  @doc """
  Deletes a book.

  ## Examples

      iex> delete_book(authorized_scope, book)
      {:ok, %Book{}}

      iex> delete_book(authorized_scope, book)
      {:error, :unauthorized}

  """
  @spec delete_book(Scope.t(), Book.t()) :: {:ok, Book.t()} | {:error, :unauthorized}
  defdelegate delete_book(scope, book), to: DeleteBook, as: :call

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking book changes.

  ## Examples

      iex> change_book(book)
      %Ecto.Changeset{data: %Book{}}

  """
  @spec change_book(Book.t(), change_book_attrs()) :: Ecto.Changeset.t()
  defdelegate change_book(book, attrs \\ %{}), to: ChangeBook, as: :call

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
  @spec create_category(Scope.t(), Book.t(), CreateCategory.create_attrs()) ::
          {:ok, Category.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  defdelegate create_category(scope, book, attrs \\ %{}), to: CreateCategory, as: :call

  @doc """
  Deletes a category.

  ## Examples

      iex> delete_category(authorized_scope, book, category)
      {:ok, %Category{}}

      iex> delete_category(unauthorized_scope, book, category)
      {:error, :unauthorized}

  """
  @spec delete_category(Scope.t(), Book.t(), Category.t()) ::
          {:ok, Category.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def delete_category(%Scope{} = scope, %Book{} = book, %Category{} = category) do
    with :ok <- Policy.authorize(:category_delete, scope, %{book: book}),
         {:ok, %Category{} = category} <-
           Repo.delete(category) do
      broadcast_book(book, {:category_deleted, category})
      {:ok, category}
    end
  end

  @doc """
  Fetches a single `Category` by its `external_id` from a specific book with optional preloading of associations.

  Returns a tuple of `{:ok, category}` if the category exists, or `{:error, :not_found}` if not found.
  Returns `{:error, :unauthorized}` if the given scope is not authorized to view the category.

  ## Preloading options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[:envelopes]` - preloads the envelopes associated with this category

  ## Examples

      iex> fetch_category_by_external_id(authorized_scope, book, "abcd-1234", preload: [:envelopes])
      {:ok, %Category{envelopes: [%Envelope{}, ...]}}

      iex> fetch_category_by_external_id(authorized_scope, book, "invalid-id")
      {:error, :not_found}

      iex> fetch_category_by_external_id(unauthorized_scope, book, "abcd-1234")
      {:error, :unauthorized}

  """
  @spec fetch_category_by_external_id(Scope.t(), Book.t(), Ecto.UUID.t(), fetch_category_by_external_id_options()) ::
          {:ok, Category.t()} | {:error, :not_found | :unauthorized}
  def fetch_category_by_external_id(%Scope{} = scope, %Book{} = book, external_id, opts \\ []) do
    with :ok <- Policy.authorize(:category_read, scope, %{book: book}) do
      case Repo.get_by(Category, external_id: external_id, book_id: book.id) do
        nil ->
          {:error, :not_found}

        category ->
          preloads = Keyword.get(opts, :preload, [])
          category = if preloads == [], do: category, else: Repo.preload(category, preloads)
          {:ok, category}
      end
    end
  end

  @doc """
  Returns a list of categories for a given book.

  ## Preloading options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[:envelopes]` - preloads the envelopes associated with categories

  ## Examples

      iex> list_categories(authorized_scope, book)
      [%Category{}, ...]

      iex> list_categories(authorized_scope, book, preload: [:envelopes])
      [%Category{envelopes: [%Envelope{}, ...]}, ...]

      iex> list_categories(unauthorized_scope, book)
      {:error, :unauthorized}

  """
  @spec list_categories(Scope.t(), Book.t(), list_categories_options()) ::
          list(Category.t()) | {:error, :unauthorized}
  def list_categories(%Scope{} = scope, %Book{} = book, opts \\ []) do
    with :ok <- Policy.authorize(:category_read, scope, %{book: book}) do
      categories =
        Category
        |> where([c], c.book_id == ^book.id)
        |> Repo.all()

      preloads = Keyword.get(opts, :preload, [])
      if preloads == [], do: categories, else: Repo.preload(categories, preloads)
    end
  end

  @doc """
  Updates a category.

  ## Preloading options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[:envelopes]` - preloads only envelopes

  ## Examples

      iex> update_category(authorized_scope, book, category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_category(authorized_scope, book, category, %{field: new_value}, preload: [:envelopes])
      {:ok, %Category{envelopes: [%Envelope{}, ...]}}

      iex> update_category(authorized_scope, book, category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> update_category(unauthorized_scope, book, category, %{field: new_value})
      {:error, :unauthorized}

  """
  @spec update_category(Scope.t(), Book.t(), Category.t(), update_category_attrs(), update_category_options()) ::
          {:ok, Category.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def update_category(%Scope{} = scope, %Book{} = book, %Category{} = category, attrs, opts \\ []) do
    attrs = Utilities.atomize_keys(attrs)

    with :ok <- Policy.authorize(:category_update, scope, %{book: book}),
         {:ok, %Category{} = category} <-
           category
           |> Category.changeset(attrs)
           |> Repo.update() do
      preloads = Keyword.get(opts, :preload, [])
      category = Repo.preload(category, preloads)

      broadcast_book(book, {:category_updated, category})
      {:ok, category}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> change_category(category)
      %Ecto.Changeset{data: %Category{}}

  """
  @spec change_category(Category.t(), map()) :: Ecto.Changeset.t()
  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  @doc """
  Creates an envelope for a category.

  ## Examples

      iex> create_envelope(authorized_scope, book, category, %{name: "Groceries"})
      {:ok, %Envelope{}}

      iex> create_envelope(authorized_scope, book, category, %{name: ""})
      {:error, %Ecto.Changeset{}}

      iex> create_envelope(unauthorized_scope, book, category, %{name: "Groceries"})
      {:error, :unauthorized}

  """
  @spec create_envelope(Scope.t(), Book.t(), Category.t(), create_envelope_attrs()) ::
          {:ok, Envelope.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def create_envelope(%Scope{} = scope, %Book{} = book, %Category{} = category, attrs \\ %{}) do
    with :ok <- Policy.authorize(:envelope_create, scope, %{book: book}) do
      attrs =
        attrs
        |> Utilities.atomize_keys()
        |> Map.put(:category_id, category.id)

      %Envelope{}
      |> Envelope.changeset(attrs)
      |> Repo.insert()
      |> case do
        {:ok, envelope} ->
          broadcast_book(book, {:envelope_created, envelope})
          {:ok, envelope}

        error ->
          error
      end
    end
  end

  @doc """
  Deletes an envelope.

  ## Examples

      iex> delete_envelope(authorized_scope, book, envelope)
      {:ok, %Envelope{}}

      iex> delete_envelope(unauthorized_scope, book, envelope)
      {:error, :unauthorized}

  """
  @spec delete_envelope(Scope.t(), Book.t(), Envelope.t()) ::
          {:ok, Envelope.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def delete_envelope(%Scope{} = scope, %Book{} = book, %Envelope{} = envelope) do
    with :ok <- Policy.authorize(:envelope_delete, scope, %{book: book}),
         {:ok, %Envelope{} = envelope} <-
           Repo.delete(envelope) do
      broadcast_book(book, {:envelope_deleted, envelope})
      {:ok, envelope}
    end
  end

  @doc """
  Fetches a single `Envelope` by its `external_id` from a specific book.

  Returns a tuple of `{:ok, envelope}` if the envelope exists, or `{:error, :not_found}` if not found.
  Returns `{:error, :unauthorized}` if the given scope is not authorized to view the envelope.

  ## Examples

      iex> fetch_envelope_by_external_id(authorized_scope, book, "abcd-1234")
      {:ok, %Envelope{}}

      iex> fetch_envelope_by_external_id(authorized_scope, book, "invalid-id")
      {:error, :not_found}

      iex> fetch_envelope_by_external_id(unauthorized_scope, book, "abcd-1234")
      {:error, :unauthorized}

      iex> fetch_envelope_by_external_id(authorized_scope, book, "abcd-1234", preload: [:category])
      {:ok, %Envelope{category: %Category{}}}

  """
  @spec fetch_envelope_by_external_id(Scope.t(), Book.t(), Ecto.UUID.t(), fetch_envelope_by_external_id_options()) ::
          {:ok, Envelope.t()} | {:error, :not_found | :unauthorized}
  def fetch_envelope_by_external_id(%Scope{} = scope, %Book{} = book, external_id, opts \\ []) do
    with :ok <- Policy.authorize(:envelope_read, scope, %{book: book}) do
      Envelope
      |> join(:inner, [e], c in Category, on: e.category_id == c.id)
      |> where([e, c], e.external_id == ^external_id and c.book_id == ^book.id)
      |> Repo.one()
      |> case do
        nil ->
          {:error, :not_found}

        envelope ->
          preloads = Keyword.get(opts, :preload, [])
          envelope = if preloads == [], do: envelope, else: Repo.preload(envelope, preloads)
          {:ok, envelope}
      end
    end
  end

  @doc """
  Updates an envelope.

  ## Examples

      iex> update_envelope(authorized_scope, book, envelope, %{field: new_value})
      {:ok, %Envelope{}}

      iex> update_envelope(authorized_scope, book, envelope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> update_envelope(unauthorized_scope, book, envelope, %{field: new_value})
      {:error, :unauthorized}

  """
  @spec update_envelope(Scope.t(), Book.t(), Envelope.t(), update_envelope_attrs()) ::
          {:ok, Envelope.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def update_envelope(%Scope{} = scope, %Book{} = book, %Envelope{} = envelope, attrs) do
    attrs = Utilities.atomize_keys(attrs)

    with :ok <- Policy.authorize(:envelope_update, scope, %{book: book}),
         {:ok, %Envelope{} = envelope} <-
           envelope
           |> Envelope.changeset(attrs)
           |> Repo.update() do
      broadcast_book(book, {:envelope_updated, envelope})
      {:ok, envelope}
    end
  end

  @doc """
  Returns a changeset for tracking envelope changes.

  ## Examples

      iex> change_envelope(envelope)
      %Ecto.Changeset{data: %Envelope{}}

  """
  @spec change_envelope(Envelope.t(), map()) :: Ecto.Changeset.t()
  def change_envelope(%Envelope{} = envelope, attrs \\ %{}) do
    Envelope.changeset(envelope, attrs)
  end
end
