defmodule PurseCraft.Repository do
  @moduledoc """
  Behaviour for repository modules.

  Provides common imports via `use PurseCraft.Repository`.

  ## Example

      defmodule PurseCraft.Identity.Repositories.UserRepository do
        use PurseCraft.Repository

        # PurseCraft.Repo is now aliased, no need to import manually
        def get_by_id(id) do
          Repo.get(UserReadModel, id)
        end
      end
  """

  defmacro __using__(_opts) do
    quote do
      alias PurseCraft.Repo
    end
  end
end
