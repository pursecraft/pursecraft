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
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Repo
  alias PurseCraft.Utilities

  @type preload_item :: atom() | {atom(), preload_item()} | [preload_item()]
  @type preload :: preload_item() | [preload_item()]

  @type create_book_attrs :: %{
          optional(:name) => String.t()
        }

  @type fetch_book_by_external_id_option :: {:preload, preload()}
  @type fetch_book_by_external_id_options :: [fetch_book_by_external_id_option()]

  @type update_book_attrs :: %{
          optional(:name) => String.t()
        }

  @type change_book_attrs :: %{
          optional(:name) => String.t()
        }

  @type create_category_attrs :: %{
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
      attrs =
        attrs
        |> Utilities.atomize_keys()
        |> Map.put(:book_id, book.id)
        |> Map.put_new(:position, 0)

      # Use a transaction to ensure atomicity
      Ecto.Multi.new()
      |> Ecto.Multi.run(:shift_positions, fn repo, _changes ->
        # Shift all existing categories in this book down by 1
        Category
        |> where([c], c.book_id == ^book.id)
        |> update([c], inc: [position: 1])
        |> repo.update_all([])

        {:ok, nil}
      end)
      |> Ecto.Multi.insert(:category, Category.changeset(%Category{}, attrs))
      |> Repo.transaction()
      |> case do
        {:ok, %{category: category}} ->
          broadcast_book(book, {:category_created, category})
          {:ok, category}

        {:error, _failed_operation, changeset, _changes} ->
          {:error, changeset}
      end
    end
  end

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
        |> order_by([c], c.position)
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
        |> Map.put_new(:position, 0)

      # Use a transaction to ensure atomicity
      Ecto.Multi.new()
      |> Ecto.Multi.run(:shift_positions, fn repo, _changes ->
        # Shift all existing envelopes in this category down by 1
        Envelope
        |> where([e], e.category_id == ^category.id)
        |> update([e], inc: [position: 1])
        |> repo.update_all([])

        {:ok, nil}
      end)
      |> Ecto.Multi.insert(:envelope, Envelope.changeset(%Envelope{}, attrs))
      |> Repo.transaction()
      |> case do
        {:ok, %{envelope: envelope}} ->
          broadcast_book(book, {:envelope_created, envelope})
          {:ok, envelope}

        {:error, _failed_operation, changeset, _changes} ->
          {:error, changeset}
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

  @doc """
  Reorders a category within its book by changing its position and adjusting other categories.

  This function ensures consistent ordering by:
  1. Moving the category to the target position
  2. Adjusting other categories' positions to maintain a contiguous sequence

  ## Examples

      iex> reorder_category(authorized_scope, book, category, 3)
      {:ok, %Category{position: 3}}

      iex> reorder_category(authorized_scope, book, category, -1)
      {:error, :invalid_position}

      iex> reorder_category(unauthorized_scope, book, category, 3)
      {:error, :unauthorized}

  """
  @spec reorder_category(Scope.t(), Book.t(), Category.t(), integer()) ::
          {:ok, Category.t()} | {:error, atom() | Ecto.Changeset.t()}
  def reorder_category(%Scope{} = scope, %Book{} = book, %Category{} = category, new_position)
      when is_integer(new_position) and new_position >= 0 do
    with :ok <- Policy.authorize(:category_update, scope, %{book: book}) do
      # Get the current list of categories for this book to determine max position
      categories = list_categories(scope, book)
      max_position = length(categories) - 1

      # If the position is greater than the max position, cap it at max_position
      new_position = min(new_position, max_position)

      # Current position of the category
      current_position = category.position

      # If the positions are the same, nothing to do
      if current_position == new_position do
        {:ok, category}
      else
        # Start a transaction to ensure all position updates are atomic
        multi = Ecto.Multi.new()

        # Define a function to handle position updates
        update_positions = fn repo, _changes ->
          query =
            Category
            |> where([c], c.book_id == ^book.id)
            |> where([c], c.id != ^category.id)

          # Apply the appropriate query based on direction
          query = apply_position_update(query, current_position, new_position)

          repo.update_all(query, [])
          {:ok, nil}
        end

        # Add the operation to the transaction
        multi = Ecto.Multi.run(multi, :shift_other_categories, update_positions)

        # Complete the transaction
        multi
        |> Ecto.Multi.update(:category, Category.position_changeset(category, new_position))
        |> Repo.transaction()
        |> case do
          {:ok, %{category: updated_category}} ->
            broadcast_book(book, {:category_updated, updated_category})
            {:ok, updated_category}

          {:error, _failed_operation, failed_value, _changes} ->
            {:error, failed_value}
        end
      end
    end
  end

  def reorder_category(_scope, _book, _category, _new_position) do
    {:error, :invalid_position}
  end

  # Helper function to apply position update based on direction
  defp apply_position_update(query, current_position, new_position) do
    if current_position < new_position do
      # Moving down, decrement positions for items in between
      query
      |> where([item], item.position > ^current_position and item.position <= ^new_position)
      |> update([item], set: [position: fragment("position - 1")])
    else
      # Moving up, increment positions for items in between
      query
      |> where([item], item.position >= ^new_position and item.position < ^current_position)
      |> update([item], set: [position: fragment("position + 1")])
    end
  end

  @doc """
  Reorders an envelope within its category by changing its position and adjusting other envelopes.

  This function ensures consistent ordering by:
  1. Moving the envelope to the target position
  2. Adjusting other envelopes' positions to maintain a contiguous sequence

  ## Examples

      iex> reorder_envelope(authorized_scope, book, envelope, 3)
      {:ok, %Envelope{position: 3}}

      iex> reorder_envelope(authorized_scope, book, envelope, -1)
      {:error, :invalid_position}

      iex> reorder_envelope(unauthorized_scope, book, envelope, 3)
      {:error, :unauthorized}

  """
  @spec reorder_envelope(Scope.t(), Book.t(), Envelope.t(), integer()) ::
          {:ok, Envelope.t()} | {:error, atom() | Ecto.Changeset.t()}
  def reorder_envelope(%Scope{} = scope, %Book{} = book, %Envelope{} = envelope, new_position)
      when is_integer(new_position) and new_position >= 0 do
    with :ok <- Policy.authorize(:envelope_update, scope, %{book: book}) do
      # Need to fetch the category to know how many envelopes it has
      category =
        Category
        |> Repo.get(envelope.category_id)
        |> Repo.preload(:envelopes)

      envelopes = Enum.sort_by(category.envelopes, & &1.position)
      max_position = length(envelopes) - 1

      # If the position is greater than the max position, cap it at max_position
      new_position = min(new_position, max_position)

      # Current position of the envelope
      current_position = envelope.position

      # If the positions are the same, nothing to do
      if current_position == new_position do
        {:ok, envelope}
      else
        # Start a transaction to ensure all position updates are atomic
        multi = Ecto.Multi.new()

        # Define a function to handle position updates
        update_positions = fn repo, _changes ->
          query =
            Envelope
            |> where([e], e.category_id == ^envelope.category_id)
            |> where([e], e.id != ^envelope.id)

          # Apply the appropriate query based on direction
          query = apply_position_update(query, current_position, new_position)

          repo.update_all(query, [])
          {:ok, nil}
        end

        # Add the operation to the transaction
        multi = Ecto.Multi.run(multi, :shift_other_envelopes, update_positions)

        # Complete the transaction
        multi
        |> Ecto.Multi.update(:envelope, Envelope.position_changeset(envelope, new_position))
        |> Repo.transaction()
        |> case do
          {:ok, %{envelope: updated_envelope}} ->
            broadcast_book(book, {:envelope_updated, updated_envelope})
            {:ok, updated_envelope}

          {:error, _failed_operation, failed_value, _changes} ->
            {:error, failed_value}
        end
      end
    end
  end

  def reorder_envelope(_scope, _book, _envelope, _new_position) do
    {:error, :invalid_position}
  end

  @doc """
  Moves an envelope from one category to another with position handling.

  This function:
  1. Changes the envelope's category
  2. Places the envelope at the specified position in the target category
  3. Adjusts positions of other envelopes in both the source and target categories

  ## Examples

      iex> move_envelope(authorized_scope, book, envelope, target_category, 0)
      {:ok, %Envelope{}}

      iex> move_envelope(authorized_scope, book, envelope, target_category, -1)
      {:error, :invalid_position}

      iex> move_envelope(unauthorized_scope, book, envelope, target_category, 0)
      {:error, :unauthorized}

  """
  @spec move_envelope(Scope.t(), Book.t(), Envelope.t(), Category.t(), integer()) ::
          {:ok, Envelope.t()} | {:error, atom() | Ecto.Changeset.t()}
  def move_envelope(%Scope{} = scope, %Book{} = book, %Envelope{} = envelope, %Category{} = target_category, new_position)
      when is_integer(new_position) and new_position >= 0 do
    with :ok <- Policy.authorize(:envelope_update, scope, %{book: book}) do
      # Can't move to the same category
      if envelope.category_id == target_category.id do
        # Use reorder_envelope instead
        reorder_envelope(scope, book, envelope, new_position)
      else
        # Get the source category and its envelopes to adjust their positions
        source_category_id = envelope.category_id
        current_position = envelope.position

        # Count envelopes in target category to validate new_position
        target_envelopes_count =
          Envelope
          |> where([e], e.category_id == ^target_category.id)
          |> select([e], count(e.id))
          |> Repo.one()

        # Cap the position at the end of the target category's envelopes
        capped_position = min(new_position, target_envelopes_count)

        # Start a transaction for all operations
        Ecto.Multi.new()
        |> Ecto.Multi.run(:adjust_source_category, fn repo, _changes ->
          # Close the gap in the source category
          Envelope
          |> where([e], e.category_id == ^source_category_id and e.position > ^current_position)
          |> update([e], set: [position: fragment("position - 1")])
          |> repo.update_all([])

          {:ok, nil}
        end)
        |> Ecto.Multi.run(:adjust_target_category, fn repo, _changes ->
          # Make space in the target category
          Envelope
          |> where([e], e.category_id == ^target_category.id and e.position >= ^capped_position)
          |> update([e], set: [position: fragment("position + 1")])
          |> repo.update_all([])

          {:ok, nil}
        end)
        |> Ecto.Multi.update(
          :envelope,
          Envelope.changeset(envelope, %{
            category_id: target_category.id,
            position: capped_position
          })
        )
        |> Repo.transaction()
        |> case do
          {:ok, %{envelope: updated_envelope}} ->
            broadcast_book(book, {:envelope_updated, updated_envelope})
            {:ok, updated_envelope}

          {:error, _failed_operation, failed_value, _changes} ->
            {:error, failed_value}
        end
      end
    end
  end

  def move_envelope(_scope, _book, _envelope, _target_category, _new_position) do
    {:error, :invalid_position}
  end
end
