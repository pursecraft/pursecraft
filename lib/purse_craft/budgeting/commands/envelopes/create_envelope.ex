defmodule PurseCraft.Budgeting.Commands.Envelopes.CreateEnvelope do
  @moduledoc """
  Creates an envelope and associates it with the given `Category`.
  """

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.EnvelopeRepository
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.Identity.Schemas.Book
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub.BroadcastBook
  alias PurseCraft.Utilities
  alias PurseCraft.Utilities.FractionalIndexing

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
          {:ok, Envelope.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized} | {:error, :cannot_place_at_top}
  def call(%Scope{} = scope, %Book{} = book, %Category{} = category, attrs \\ %{}) do
    with :ok <- Policy.authorize(:envelope_create, scope, %{book: book}),
         first_position = EnvelopeRepository.get_first_position(category.id),
         {:ok, position} <- generate_top_position(first_position),
         attrs = build_attrs(attrs, category.id, position),
         {:ok, envelope} <- EnvelopeRepository.create(attrs) do
      BroadcastBook.call(book, {:envelope_created, envelope})
      {:ok, envelope}
    end
  end

  defp generate_top_position(first_position) do
    case FractionalIndexing.between(nil, first_position) do
      {:ok, position} -> {:ok, position}
      {:error, :cannot_go_before_a} -> {:error, :cannot_place_at_top}
    end
  end

  defp build_attrs(attrs, category_id, position) do
    attrs
    |> Utilities.atomize_keys()
    |> Map.put(:category_id, category_id)
    |> Map.put(:position, position)
  end
end
