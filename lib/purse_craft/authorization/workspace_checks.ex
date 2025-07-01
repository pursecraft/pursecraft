defmodule PurseCraft.Authorization.WorkspaceChecks do
  @moduledoc """
  Shared workspace-level authorization checks used across contexts
  """

  import Ecto.Query

  alias PurseCraft.Cache
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Core.Schemas.WorkspaceUser
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Identity.Schemas.User
  alias PurseCraft.Repo

  @spec own_resource(Scope.t(), any()) :: boolean()
  def own_resource(%Scope{user: %User{} = user}, %{workspace: %Workspace{} = workspace}) do
    case get_workspace_user(workspace, user) do
      nil ->
        false

      _workspace_user ->
        true
    end
  end

  # coveralls-ignore-start
  def own_resource(_scope, _object), do: false
  # coveralls-ignore-stop

  @spec role(Scope.t(), any(), atom()) :: boolean()
  def role(%Scope{user: %User{} = user}, %{workspace: %Workspace{} = workspace}, role) do
    case get_workspace_user(workspace, user) do
      nil ->
        false

      workspace_user ->
        role == workspace_user.role
    end
  end

  # coveralls-ignore-start
  def role(_scope, _object, _role), do: false
  # coveralls-ignore-stop

  defp get_workspace_user(%Workspace{id: nil, external_id: workspace_external_id}, %User{id: user_id}) do
    cache_key = {:authorization_check, {:workspace_user, {:workspace_external_id, {workspace_external_id, user_id}}}}

    case Cache.get(cache_key) do
      nil ->
        workspace_user =
          WorkspaceUser
          |> join(:inner, [wu], w in Workspace, on: wu.workspace_id == w.id)
          |> where([_wu, w], w.external_id == ^workspace_external_id)
          |> where([wu], wu.user_id == ^user_id)
          |> Repo.one()

        Cache.put(cache_key, workspace_user)
        workspace_user

      cached_workspace_user ->
        cached_workspace_user
    end
  end

  defp get_workspace_user(%Workspace{id: workspace_id}, %User{id: user_id}) do
    cache_key = {:authorization_check, {:workspace_user, {:workspace_id, {workspace_id, user_id}}}}

    case Cache.get(cache_key) do
      nil ->
        workspace_user =
          WorkspaceUser
          |> join(:inner, [wu], w in Workspace, on: wu.workspace_id == w.id)
          |> where([_wu, w], w.id == ^workspace_id)
          |> where([wu], wu.user_id == ^user_id)
          |> Repo.one()

        Cache.put(cache_key, workspace_user)
        workspace_user

      cached_workspace_user ->
        cached_workspace_user
    end
  end

  # coveralls-ignore-start
  defp get_workspace_user(_workspace, _user), do: nil
  # coveralls-ignore-stop
end
