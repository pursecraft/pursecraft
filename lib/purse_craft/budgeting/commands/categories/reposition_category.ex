defmodule PurseCraft.Budgeting.Commands.Categories.RepositionCategory do
  @moduledoc """
  Repositions a category between two other categories using fractional indexing.
  """

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.CategoryRepository
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub
  alias PurseCraft.Repo
  alias PurseCraft.Utilities
  alias PurseCraft.Utilities.FractionalIndexing

  @max_retries 3

  @doc """
  Repositions a category between two other categories.

  Takes the category's external ID and optionally the external IDs of the
  previous and next categories. If prev_category_id is nil, the category
  will be positioned before all others. If next_category_id is nil, the
  category will be positioned after all others.

  ## Examples

      iex> call(scope, "cat-123", nil, "cat-456")
      {:ok, %Category{position: "g"}}
      
      iex> call(scope, "cat-123", "cat-456", nil)
      {:ok, %Category{position: "s"}}
      
      iex> call(scope, "cat-123", "cat-456", "cat-789")
      {:ok, %Category{position: "m"}}
      
      iex> call(unauthorized_scope, "cat-123", nil, nil)
      {:error, :unauthorized}
      
  """
  @spec call(Scope.t(), Ecto.UUID.t(), Ecto.UUID.t() | nil, Ecto.UUID.t() | nil) ::
          {:ok, Category.t()} | {:error, atom() | Ecto.Changeset.t()}
  def call(%Scope{} = scope, category_id, prev_category_id, next_category_id) do
    ids_to_fetch =
      [category_id, prev_category_id, next_category_id]
      |> Enum.filter(&(&1 != nil))
      |> Enum.uniq()

    categories = CategoryRepository.list_by_external_ids(ids_to_fetch, preload: [:workspace])
    categories_map = Map.new(categories, &{&1.external_id, &1})

    with {:ok, [category, prev_category, next_category]} <-
           validate_and_extract_categories(
             categories_map,
             category_id,
             prev_category_id,
             next_category_id
           ),
         :ok <- Policy.authorize(:category_update, scope, %{workspace: category.workspace}) do
      result =
        Repo.transaction(fn ->
          case attempt_reposition(category, prev_category, next_category, @max_retries) do
            {:ok, updated} -> updated
            {:error, reason} -> Repo.rollback(reason)
          end
        end)

      case result do
        {:ok, updated} ->
          PubSub.broadcast_workspace(category.workspace, {:category_repositioned, updated})
          {:ok, updated}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp validate_and_extract_categories(categories_map, category_id, prev_category_id, next_category_id) do
    with {:ok, category} <-
           categories_map
           |> Map.get(category_id)
           |> Utilities.to_result(),
         {:ok, prev_category} <- validate_optional_category(categories_map, prev_category_id, category.workspace_id),
         {:ok, next_category} <- validate_optional_category(categories_map, next_category_id, category.workspace_id) do
      {:ok, [category, prev_category, next_category]}
    end
  end

  defp validate_optional_category(_categories_map, nil, _workspace_id), do: {:ok, nil}

  defp validate_optional_category(categories_map, category_id, workspace_id) do
    case Map.get(categories_map, category_id) do
      nil ->
        {:error, :not_found}

      category ->
        if category.workspace_id == workspace_id do
          {:ok, category}
        else
          {:error, :not_found}
        end
    end
  end

  defp attempt_reposition(category, prev_category, next_category, retries_left) do
    prev_position = if prev_category, do: prev_category.position
    next_position = if next_category, do: next_category.position

    case FractionalIndexing.between(prev_position, next_position) do
      {:ok, new_position} ->
        handle_position_update(category, prev_category, next_category, new_position, retries_left)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp handle_position_update(category, prev_category, next_category, new_position, retries_left) do
    case CategoryRepository.update_position(category, new_position) do
      {:ok, updated} ->
        {:ok, updated}

      {:error, changeset} ->
        if retries_left > 0 && has_unique_constraint_error?(changeset) do
          retry_with_modified_position(category, prev_category, next_category, new_position, retries_left)
        else
          {:error, changeset}
        end
    end
  end

  defp retry_with_modified_position(category, prev_category, next_category, new_position, retries_left) do
    suffix = Enum.random(["a", "m", "z"])
    new_position_with_suffix = new_position <> suffix

    modified_next =
      if next_category do
        %{next_category | position: new_position_with_suffix}
      else
        # coveralls-ignore-next-line
        %Category{position: new_position_with_suffix}
      end

    attempt_reposition(category, prev_category, modified_next, retries_left - 1)
  end

  defp has_unique_constraint_error?(changeset) do
    Enum.any?(changeset.errors, fn
      {:position, {"has already been taken", _opts}} -> true
      _error -> false
    end)
  end
end
