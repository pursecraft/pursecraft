defmodule PurseCraft.SearchFactory do
  @moduledoc false

  use PurseCraft.FactoryTemplate

  alias PurseCraft.Search.Schemas.SearchToken

  def search_token_factory(attrs) do
    default_attrs = %{
      field_name: "name",
      token_hash: "hel",
      algorithm_version: 1,
      token_length: 3
    }

    merged_attrs = Enum.into(attrs, default_attrs)

    search_token =
      %SearchToken{}
      |> SearchToken.changeset(merged_attrs)
      |> Ecto.Changeset.apply_changes()

    search_token
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end
end
