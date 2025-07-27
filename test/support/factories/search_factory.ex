defmodule PurseCraft.SearchFactory do
  @moduledoc false

  use PurseCraft.FactoryTemplate

  alias PurseCraft.Search.Schemas.SearchToken

  def search_token_factory(attrs) do
    field_name = Map.get(attrs, :field_name, "name")
    token_hash = Map.get(attrs, :token_hash, "hel")

    search_token =
      %SearchToken{}
      |> SearchToken.changeset(%{
        field_name: field_name,
        token_hash: token_hash,
        algorithm_version: 1,
        token_length: 3
      })
      |> Ecto.Changeset.apply_changes()

    search_token
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end
end
