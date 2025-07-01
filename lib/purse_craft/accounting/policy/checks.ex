defmodule PurseCraft.Accounting.Policy.Checks do
  @moduledoc """
  `LetMe.Policy` check module for the `Accounting` schema
  """

  alias PurseCraft.Authorization.WorkspaceChecks

  # coveralls-ignore-next-line
  defdelegate own_resource(scope, object), to: WorkspaceChecks
  defdelegate role(scope, object, role), to: WorkspaceChecks
end
