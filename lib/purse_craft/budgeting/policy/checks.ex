defmodule PurseCraft.Budgeting.Policy.Checks do
  @moduledoc """
  `LetMe.Policy` check module for the `Budgeting` schema
  """

  alias PurseCraft.Authorization.WorkspaceChecks

  defdelegate own_resource(scope, object), to: WorkspaceChecks
  defdelegate role(scope, object, role), to: WorkspaceChecks
end
