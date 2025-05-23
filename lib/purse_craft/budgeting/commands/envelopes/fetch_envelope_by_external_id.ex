defmodule PurseCraft.Budgeting.Commands.Envelopes.FetchEnvelopeByExternalId do
  @moduledoc """
  Fetches an envelope by external ID for a given book.
  """

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.EnvelopeRepository
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Types

  @type option :: {:preload, Types.preload()}
  @type options :: [option()]

  @doc """
  Fetches an envelope by external ID for a given book.

  ## Examples

      iex> call(authorized_scope, book, "abcd-1234", preload: [:category])
      {:ok, %Envelope{category: %Category{}}}

      iex> call(authorized_scope, book, "invalid-id")
      {:error, :not_found}

      iex> call(unauthorized_scope, book, "abcd-1234")
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Book.t(), Ecto.UUID.t(), options()) ::
          {:ok, Envelope.t()} | {:error, :not_found | :unauthorized}
  def call(%Scope{} = scope, %Book{} = book, external_id, opts \\ []) do
    with :ok <- Policy.authorize(:envelope_read, scope, %{book: book}) do
      case EnvelopeRepository.get_by_external_id_and_book_id(external_id, book.id, opts) do
        nil -> {:error, :not_found}
        envelope -> {:ok, envelope}
      end
    end
  end
end
