defmodule PurseCraft.Service do
  @moduledoc """
  Behaviour for service modules.

  All service modules must implement a `call/1` function that executes
  a single business operation.

  ## Example

      defmodule PurseCraft.Identity.Services.RegisterUser do
        @behaviour PurseCraft.Service

        @impl true
        def call(params) do
          # business logic here
        end
      end
  """

  @doc """
  Execute the service operation.

  Should return `{:ok, result}` or `{:error, reason}`.
  """
  @callback call(term()) :: {:ok, term()} | {:error, term()}
end
