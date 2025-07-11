defmodule PurseCraft.Budgeting do
  @moduledoc """
  The Budgeting context.
  """

  import Ecto.Query, warn: false

  alias PurseCraft.Budgeting.Commands.Categories.ChangeCategory
  alias PurseCraft.Budgeting.Commands.Categories.CreateCategory
  alias PurseCraft.Budgeting.Commands.Categories.DeleteCategory
  alias PurseCraft.Budgeting.Commands.Categories.FetchCategoryByExternalId
  alias PurseCraft.Budgeting.Commands.Categories.ListCategories
  alias PurseCraft.Budgeting.Commands.Categories.UpdateCategory
  alias PurseCraft.Budgeting.Commands.Envelopes.ChangeEnvelope
  alias PurseCraft.Budgeting.Commands.Envelopes.CreateEnvelope
  alias PurseCraft.Budgeting.Commands.Envelopes.DeleteEnvelope
  alias PurseCraft.Budgeting.Commands.Envelopes.FetchEnvelopeByExternalId
  alias PurseCraft.Budgeting.Commands.Envelopes.UpdateEnvelope
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope

  @doc """
  Creates a category for a workspace.

  ## Examples

      iex> create_category(authorized_scope, workspace, %{field: value})
      {:ok, %Category{}}

      iex> create_category(authorized_scope, workspace, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> create_category(unauthorized_scope, workspace, %{field: value})
      {:error, :unauthorized}

  """
  @spec create_category(Scope.t(), Workspace.t(), CreateCategory.create_attrs()) ::
          {:ok, Category.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized} | {:error, :cannot_place_at_top}
  defdelegate create_category(scope, workspace, attrs \\ %{}), to: CreateCategory, as: :call

  @doc """
  Deletes a category.

  ## Examples

      iex> delete_category(authorized_scope, workspace, category)
      {:ok, %Category{}}

      iex> delete_category(unauthorized_scope, workspace, category)
      {:error, :unauthorized}

  """
  @spec delete_category(Scope.t(), Workspace.t(), Category.t()) ::
          {:ok, Category.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  defdelegate delete_category(scope, workspace, category), to: DeleteCategory, as: :call

  @doc """
  Fetches a single `Category` by its `external_id` from a specific workspace with optional preloading of associations.

  Returns a tuple of `{:ok, category}` if the category exists, or `{:error, :not_found}` if not found.
  Returns `{:error, :unauthorized}` if the given scope is not authorized to view the category.

  ## Preloading options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[:envelopes]` - preloads the envelopes associated with this category

  ## Examples

      iex> fetch_category_by_external_id(authorized_scope, workspace, "abcd-1234", preload: [:envelopes])
      {:ok, %Category{envelopes: [%Envelope{}, ...]}}

      iex> fetch_category_by_external_id(authorized_scope, workspace, "invalid-id")
      {:error, :not_found}

      iex> fetch_category_by_external_id(unauthorized_scope, workspace, "abcd-1234")
      {:error, :unauthorized}

  """
  @spec fetch_category_by_external_id(Scope.t(), Workspace.t(), Ecto.UUID.t(), FetchCategoryByExternalId.options()) ::
          {:ok, Category.t()} | {:error, :not_found | :unauthorized}
  defdelegate fetch_category_by_external_id(scope, workspace, external_id, opts \\ []),
    to: FetchCategoryByExternalId,
    as: :call

  @doc """
  Returns a list of categories for a given workspace.

  ## Preloading options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[:envelopes]` - preloads the envelopes associated with categories

  ## Examples

      iex> list_categories(authorized_scope, workspace)
      [%Category{}, ...]

      iex> list_categories(authorized_scope, workspace, preload: [:envelopes])
      [%Category{envelopes: [%Envelope{}, ...]}, ...]

      iex> list_categories(unauthorized_scope, workspace)
      {:error, :unauthorized}

  """
  @spec list_categories(Scope.t(), Workspace.t(), ListCategories.options()) ::
          list(Category.t()) | {:error, :unauthorized}
  defdelegate list_categories(scope, workspace, opts \\ []), to: ListCategories, as: :call

  @doc """
  Updates a category.

  ## Preloading options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[:envelopes]` - preloads only envelopes

  ## Examples

      iex> update_category(authorized_scope, workspace, category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_category(authorized_scope, workspace, category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> update_category(unauthorized_scope, workspace, category, %{field: new_value})
      {:error, :unauthorized}

  """
  @spec update_category(Scope.t(), Workspace.t(), Category.t(), UpdateCategory.attrs(), UpdateCategory.options()) ::
          {:ok, Category.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  defdelegate update_category(scope, workspace, category, attrs, opts \\ []), to: UpdateCategory, as: :call

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> change_category(category)
      %Ecto.Changeset{data: %Category{}}

  """
  @spec change_category(Category.t(), map()) :: Ecto.Changeset.t()
  defdelegate change_category(category, attrs \\ %{}), to: ChangeCategory, as: :call

  @doc """
  Creates an envelope for a category.

  ## Examples

      iex> create_envelope(authorized_scope, workspace, category, %{field: value})
      {:ok, %Envelope{}}

      iex> create_envelope(authorized_scope, workspace, category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> create_envelope(unauthorized_scope, workspace, category, %{field: value})
      {:error, :unauthorized}

  """
  @spec create_envelope(Scope.t(), Workspace.t(), Category.t(), CreateEnvelope.attrs()) ::
          {:ok, Envelope.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  defdelegate create_envelope(scope, workspace, category, attrs \\ %{}), to: CreateEnvelope, as: :call

  @doc """
  Deletes an envelope.

  ## Examples

      iex> delete_envelope(authorized_scope, workspace, envelope)
      {:ok, %Envelope{}}

      iex> delete_envelope(unauthorized_scope, workspace, envelope)
      {:error, :unauthorized}

  """
  @spec delete_envelope(Scope.t(), Workspace.t(), Envelope.t()) ::
          {:ok, Envelope.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  defdelegate delete_envelope(scope, workspace, envelope), to: DeleteEnvelope, as: :call

  @doc """
  Fetches a single `Envelope` by its `external_id` from a specific workspace.

  Returns a tuple of `{:ok, envelope}` if the envelope exists, or `{:error, :not_found}` if not found.
  Returns `{:error, :unauthorized}` if the given scope is not authorized to view the envelope.

  ## Examples

      iex> fetch_envelope_by_external_id(authorized_scope, workspace, "abcd-1234")
      {:ok, %Envelope{}}

      iex> fetch_envelope_by_external_id(authorized_scope, workspace, "invalid-id")
      {:error, :not_found}

      iex> fetch_envelope_by_external_id(authorized_scope, workspace, "abcd-1234", preload: [:category])
      {:ok, %Envelope{category: %Category{}}}

  """
  @spec fetch_envelope_by_external_id(Scope.t(), Workspace.t(), Ecto.UUID.t(), FetchEnvelopeByExternalId.options()) ::
          {:ok, Envelope.t()} | {:error, :not_found | :unauthorized}
  defdelegate fetch_envelope_by_external_id(scope, workspace, external_id, opts \\ []),
    to: FetchEnvelopeByExternalId,
    as: :call

  @doc """
  Updates an envelope.

  ## Examples

      iex> update_envelope(authorized_scope, workspace, envelope, %{field: new_value})
      {:ok, %Envelope{}}

      iex> update_envelope(authorized_scope, workspace, envelope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> update_envelope(unauthorized_scope, workspace, envelope, %{field: new_value})
      {:error, :unauthorized}

  """
  @spec update_envelope(Scope.t(), Workspace.t(), Envelope.t(), UpdateEnvelope.attrs()) ::
          {:ok, Envelope.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  defdelegate update_envelope(scope, workspace, envelope, attrs), to: UpdateEnvelope, as: :call

  @doc """
  Returns a changeset for tracking envelope changes.

  ## Examples

      iex> change_envelope(envelope)
      %Ecto.Changeset{data: %Envelope{}}

  """
  @spec change_envelope(Envelope.t(), ChangeEnvelope.attrs()) :: Ecto.Changeset.t()
  # coveralls-ignore-next-line
  defdelegate change_envelope(envelope, attrs \\ %{}), to: ChangeEnvelope, as: :call
end
