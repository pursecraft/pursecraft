defmodule PurseCraft.Utilities.PutHashedField do
  @moduledoc """
  Puts hash values for the specified fields in the changeset.

  Takes a changeset and a list of field names, and for each field that has a value,
  creates a corresponding `{field}_hash` field with the same value.

  For email fields, applies normalization (lowercase) before hashing.
  """

  import Ecto.Changeset

  @doc """
  Puts hash values for the specified fields in the changeset.

  Takes a changeset and a list of field names, and for each field that has a value,
  creates a corresponding `{field}_hash` field with the same value.

  For email fields, applies normalization (lowercase) before hashing.

  ## Examples

      changeset
      |> PutHashedField.call([:name, :account_type, :description])

      changeset 
      |> PutHashedField.call([:email])  # Will normalize email to lowercase

  """
  @spec call(Ecto.Changeset.t(), [atom()]) :: Ecto.Changeset.t()
  def call(changeset, fields) when is_list(fields) do
    Enum.reduce(fields, changeset, &put_hash_field/2)
  end

  @spec call(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def call(changeset, field) when is_atom(field) do
    put_hash_field(field, changeset)
  end

  defp put_hash_field(field, changeset) do
    case get_field(changeset, field) do
      nil ->
        changeset

      value when is_binary(value) ->
        hash_field = String.to_atom("#{field}_hash")
        normalized_value = normalize_field_value(field, value)
        put_change(changeset, hash_field, normalized_value)

      _other ->
        # coveralls-ignore-next-line
        changeset
    end
  end

  defp normalize_field_value(:email, value), do: String.downcase(value)
  defp normalize_field_value(_field, value), do: value
end
