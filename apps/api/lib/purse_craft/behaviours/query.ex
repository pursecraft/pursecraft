defmodule PurseCraft.Query do
  @moduledoc """
  Behaviour for query modules.

  Provides common imports via `use PurseCraft.Query`.

  ## Example

      defmodule PurseCraft.Identity.Queries.UserQuery do
        use PurseCraft.Query

        # Ecto.Query is now imported, no need to import manually
        def base_query do
          from(u in UserReadModel)
        end

        def by_email(email) do
          from(u in base_query(), where: u.email == ^email)
        end
      end
  """

  defmacro __using__(_opts) do
    quote do
      import Ecto.Query
    end
  end
end
