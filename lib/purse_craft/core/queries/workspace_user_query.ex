defmodule PurseCraft.Core.Queries.WorkspaceUserQuery do
  @moduledoc """
  Query functions for `WorkspaceUser`.
  """

  import Ecto.Query

  alias PurseCraft.Core.Schemas.WorkspaceUser

  @doc """
  Returns a query for workspace users associated with a specific workspace.

  ## Examples

      iex> by_workspace_id(1)
      #Ecto.Query<...>

  """
  @spec by_workspace_id(integer()) :: Ecto.Query.t()
  def by_workspace_id(workspace_id) do
    from(wu in WorkspaceUser, where: wu.workspace_id == ^workspace_id)
  end
end
