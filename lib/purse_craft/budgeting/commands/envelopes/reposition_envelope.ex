defmodule PurseCraft.Budgeting.Commands.Envelopes.RepositionEnvelope do
  @moduledoc """
  Repositions an envelope within or between categories using fractional indexing.
  """

  alias PurseCraft.Budgeting.Commands.PubSub.BroadcastCategory
  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.CategoryRepository
  alias PurseCraft.Budgeting.Repositories.EnvelopeRepository
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Repo
  alias PurseCraft.Utilities.FractionalIndexing

  @max_retries 3

  @doc """
  Repositions an envelope, optionally moving it to a different category.

  ## Examples

      iex> RepositionEnvelope.call(scope, "env-123", "cat-456", nil, "env-789")
      {:ok, %Envelope{position: "g"}}

      iex> RepositionEnvelope.call(scope, "env-123", "cat-456", "env-789", nil)
      {:ok, %Envelope{position: "s"}}

      iex> RepositionEnvelope.call(scope, "env-123", "cat-456", "env-789", "env-012")
      {:ok, %Envelope{position: "m"}}

      iex> RepositionEnvelope.call(unauthorized_scope, "env-123", "cat-456", nil, nil)
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Ecto.UUID.t(), Ecto.UUID.t(), Ecto.UUID.t() | nil, Ecto.UUID.t() | nil) ::
          {:ok, Envelope.t()} | {:error, atom() | Ecto.Changeset.t()}
  def call(%Scope{} = scope, envelope_id, target_category_id, prev_envelope_id, next_envelope_id) do
    envelope_ids_to_fetch =
      [envelope_id, prev_envelope_id, next_envelope_id]
      |> Enum.filter(&(&1 != nil))
      |> Enum.uniq()

    envelopes =
      envelope_ids_to_fetch
      |> EnvelopeRepository.list_by_external_ids(preload: [:category])
      |> Map.new(&{&1.external_id, &1})

    categories =
      [target_category_id]
      |> CategoryRepository.list_by_external_ids(preload: [:book])
      |> Map.new(&{&1.external_id, &1})

    with {:ok, envelope} <- validate_envelope(envelopes, envelope_id),
         {:ok, target_category} <- validate_target_category(categories, target_category_id),
         :ok <- Policy.authorize(:envelope_update, scope, %{book: target_category.book}),
         {:ok, [prev_envelope, next_envelope]} <-
           validate_neighbor_envelopes(
             envelopes,
             prev_envelope_id,
             next_envelope_id,
             target_category.id
           ) do
      result =
        Repo.transaction(fn ->
          case attempt_reposition(envelope, target_category, prev_envelope, next_envelope, @max_retries) do
            {:ok, updated} -> updated
            {:error, reason} -> Repo.rollback(reason)
          end
        end)

      case result do
        {:ok, updated} ->
          BroadcastCategory.call(target_category, {:envelope_repositioned, updated})

          if envelope.category_id != target_category.id do
            BroadcastCategory.call(envelope.category, {:envelope_removed, envelope})
          end

          {:ok, updated}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp validate_envelope(envelopes, envelope_id) do
    case Map.get(envelopes, envelope_id) do
      nil -> {:error, :not_found}
      envelope -> {:ok, envelope}
    end
  end

  defp validate_target_category(categories, target_category_id) do
    case Map.get(categories, target_category_id) do
      nil -> {:error, :not_found}
      category -> {:ok, category}
    end
  end

  defp validate_neighbor_envelopes(envelopes, prev_envelope_id, next_envelope_id, target_category_id) do
    with {:ok, prev_envelope} <- validate_optional_envelope(envelopes, prev_envelope_id, target_category_id),
         {:ok, next_envelope} <- validate_optional_envelope(envelopes, next_envelope_id, target_category_id) do
      {:ok, [prev_envelope, next_envelope]}
    end
  end

  defp validate_optional_envelope(_envelopes, nil, _target_category_id), do: {:ok, nil}

  defp validate_optional_envelope(envelopes, envelope_id, target_category_id) do
    case Map.get(envelopes, envelope_id) do
      nil ->
        {:error, :not_found}

      envelope ->
        if envelope.category_id == target_category_id do
          {:ok, envelope}
        else
          {:error, :not_found}
        end
    end
  end

  defp attempt_reposition(envelope, target_category, prev_envelope, next_envelope, retries_left) do
    prev_position = if prev_envelope, do: prev_envelope.position
    next_position = if next_envelope, do: next_envelope.position

    case FractionalIndexing.between(prev_position, next_position) do
      {:ok, new_position} ->
        handle_position_update(envelope, target_category, prev_envelope, next_envelope, new_position, retries_left)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp handle_position_update(envelope, target_category, prev_envelope, next_envelope, new_position, retries_left) do
    case EnvelopeRepository.update_position(envelope, new_position, target_category.id) do
      {:ok, updated} ->
        {:ok, updated}

      {:error, changeset} ->
        if retries_left > 0 && has_unique_constraint_error?(changeset) do
          retry_with_modified_position(
            envelope,
            target_category,
            prev_envelope,
            next_envelope,
            new_position,
            retries_left
          )
        else
          {:error, changeset}
        end
    end
  end

  defp retry_with_modified_position(envelope, target_category, prev_envelope, next_envelope, new_position, retries_left) do
    suffix = Enum.random(["a", "m", "z"])
    new_position_with_suffix = new_position <> suffix

    modified_next =
      if next_envelope do
        %{next_envelope | position: new_position_with_suffix}
      else
        # coveralls-ignore-next-line
        %Envelope{position: new_position_with_suffix}
      end

    attempt_reposition(envelope, target_category, prev_envelope, modified_next, retries_left - 1)
  end

  defp has_unique_constraint_error?(changeset) do
    Enum.any?(changeset.errors, fn
      {:position, {"has already been taken", _opts}} -> true
      _error -> false
    end)
  end
end
