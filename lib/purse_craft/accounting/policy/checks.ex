defmodule PurseCraft.Accounting.Policy.Checks do
  @moduledoc """
  `LetMe.Policy` check module for the `Accounting` schema
  """

  alias PurseCraft.Authorization.BookChecks

  # coveralls-ignore-next-line
  defdelegate own_resource(scope, object), to: BookChecks
  defdelegate role(scope, object, role), to: BookChecks
end
