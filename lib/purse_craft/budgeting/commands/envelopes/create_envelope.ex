defmodule PurseCraft.Budgeting.Commands.Envelopes.CreateEnvelope do
  @moduledoc """
  Creates an envelope and associates it with the given `Category`.
  """

  alias PurseCraft.Budgeting.Commands.PubSub.BroadcastBook
  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.EnvelopeRepository
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Utilities

  @type attrs :: %{
          optional(:name) => String.t()
        }

  @doc """
  Creates an envelope and associates it with the given `Category`.

  ## Examples

      iex> call(authorized_scope, book, category, %{name: "Groceries"})
      {:ok, %Envelope{}}

      iex> call(authorized_scope, book, category, %{name: ""})
      {:error, %Ecto.Changeset{}}

      iex> call(unauthorized_scope, book, category, %{name: "Groceries"})
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Book.t(), Category.t(), attrs()) ::
          {:ok, Envelope.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def call(%Scope{} = scope, %Book{} = book, %Category{} = category, attrs \\ %{}) do
    with :ok <- Policy.authorize(:envelope_create, scope, %{book: book}) do
      attrs =
        attrs
        |> Utilities.atomize_keys()
        |> Map.put(:category_id, category.id)

      case EnvelopeRepository.create(attrs) do
        {:ok, envelope} ->
          BroadcastBook.call(book, {:envelope_created, envelope})
          {:ok, envelope}

        error ->
          error
      end
    end
  end
end
