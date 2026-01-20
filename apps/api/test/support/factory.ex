defmodule PurseCraft.Factory do
  @moduledoc """
  Main factory module that composes all context-specific factories.

  Each context defines its own factories in test/support/factories/.
  Import this module to access all factories.
  """

  use ExMachina.Ecto, repo: PurseCraft.Repo
  use PurseCraft.IdentityFactory
end
