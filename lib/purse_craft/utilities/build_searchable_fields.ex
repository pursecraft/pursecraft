defmodule PurseCraft.Utilities.BuildSearchableFields do
  @moduledoc """
  Utility for building searchable fields maps from structs.

  This module provides a generic way to extract text fields from structs
  and build maps suitable for search token generation.

  ## Examples

      iex> user = %{name: "John Doe", email: "john@example.com", age: 30}
      iex> BuildSearchableFields.call(user, [:name, :email])
      %{"name" => "John Doe", "email" => "john@example.com"}

      iex> account = %{name: "Chase Checking", description: nil, balance: 1000}
      iex> BuildSearchableFields.call(account, [:name, :description])
      %{"name" => "Chase Checking"}

  """

  @type searchable_fields :: %{String.t() => String.t()}

  @doc """
  Builds a searchable fields map from a struct.

  Takes a struct and a list of field names (atoms) to extract.
  Only includes fields that have non-nil, non-empty string values.

  ## Parameters

  - `struct` - The struct to extract fields from
  - `field_names` - List of atom field names to extract

  ## Returns

  A map with string keys (field names) and string values (field contents).
  Only includes fields with valid string content.

  ## Examples

      iex> transaction = %{memo: "Groceries", amount: 2500, date: ~D[2025-01-01]}
      iex> BuildSearchableFields.call(transaction, [:memo])
      %{"memo" => "Groceries"}

      iex> payee = %{name: "Kroger", id: 123}
      iex> BuildSearchableFields.call(payee, [:name, :description])
      %{"name" => "Kroger"}

  """
  @spec call(struct() | map(), [atom()]) :: searchable_fields()
  def call(struct, field_names) when is_list(field_names) do
    Enum.reduce(field_names, %{}, fn field_name, acc ->
      maybe_add_field(acc, struct, field_name)
    end)
  end

  defp maybe_add_field(fields, struct, field_name) do
    case Map.get(struct, field_name) do
      value when is_binary(value) and value != "" ->
        Map.put(fields, Atom.to_string(field_name), value)

      _other ->
        fields
    end
  end
end
