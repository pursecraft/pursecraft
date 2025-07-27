defmodule PurseCraft.SearchFactory do
  @moduledoc false

  use PurseCraft.FactoryTemplate

  alias PurseCraft.Search.Schemas.SearchToken

  def search_token_factory(attrs) do
    # Build a minimal struct with defaults
    base_token = %SearchToken{
      field_name: "name",
      algorithm_version: 1,
      token_length: 3
    }

    # Create a changeset just for the token_hash field to apply encryption
    token_with_hash =
      base_token
      |> Ecto.Changeset.cast(%{token_hash: "hel"}, [:token_hash])
      |> Ecto.Changeset.apply_changes()

    token_with_hash
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end
end
