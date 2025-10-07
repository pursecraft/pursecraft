defmodule PurseCraft.Search.Commands.Fields.EnrichSearchFields do
  @moduledoc """
  Enriches base searchable fields with related entity information.

  For transactions, this command loads associated entities (payee, account, envelopes)
  and includes their names in the searchable fields to enable comprehensive search.

  ## Examples

      # Transaction with memo only
      iex> EnrichSearchFields.call("transaction", 123, %{"memo" => "Shopping"})
      {:ok, %{
        "memo" => "Shopping",
        "payee_name" => "Kroger Store", 
        "account_name" => "Chase Checking",
        "envelope_names" => "Groceries"
      }}

      # Non-transaction entity (passthrough)
      iex> EnrichSearchFields.call("payee", 456, %{"name" => "Target"})
      {:ok, %{"name" => "Target"}}

  """

  alias PurseCraft.Accounting.Schemas.Transaction
  alias PurseCraft.Repo

  @type entity_type :: String.t()
  @type entity_id :: integer()
  @type searchable_fields :: %{String.t() => String.t()}

  @doc """
  Enriches searchable fields based on entity type and associations.
  """
  @spec call(entity_type(), entity_id(), searchable_fields()) :: {:ok, searchable_fields()}
  def call("transaction", entity_id, base_fields) do
    enriched_fields =
      case load_transaction_with_associations(entity_id) do
        nil -> base_fields
        transaction -> build_transaction_searchable_fields(transaction, base_fields)
      end

    {:ok, enriched_fields}
  end

  def call(_entity_type, _entity_id, searchable_fields) do
    {:ok, searchable_fields}
  end

  defp load_transaction_with_associations(transaction_id) do
    Transaction
    |> Repo.get(transaction_id)
    |> Repo.preload([:payee, :account, transaction_lines: [:envelope, :payee]])
  end

  defp build_transaction_searchable_fields(transaction, base_fields) do
    base_fields
    |> maybe_add_payee_name(transaction)
    |> maybe_add_account_name(transaction)
    |> maybe_add_envelope_names(transaction)
    |> maybe_add_line_payee_names(transaction)
  end

  defp maybe_add_payee_name(fields, %{payee: %{name: name}}) when is_binary(name) do
    Map.put(fields, "payee_name", name)
  end

  defp maybe_add_payee_name(fields, _transaction), do: fields

  defp maybe_add_account_name(fields, %{account: %{name: name}}) when is_binary(name) do
    Map.put(fields, "account_name", name)
  end

  # coveralls-ignore-next-line
  defp maybe_add_account_name(fields, _transaction), do: fields

  defp maybe_add_envelope_names(fields, %{transaction_lines: lines}) do
    envelope_names =
      lines
      |> Enum.map(fn line -> line.envelope end)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn envelope -> envelope.name end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.join(" ")

    if envelope_names == "" do
      fields
    else
      Map.put(fields, "envelope_names", envelope_names)
    end
  end

  # coveralls-ignore-next-line
  defp maybe_add_envelope_names(fields, _transaction), do: fields

  defp maybe_add_line_payee_names(fields, %{transaction_lines: lines}) do
    line_payee_names =
      lines
      |> Enum.map(fn line -> line.payee end)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn payee -> payee.name end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.join(" ")

    if line_payee_names == "" do
      fields
    else
      Map.put(fields, "line_payee_names", line_payee_names)
    end
  end

  # coveralls-ignore-next-line
  defp maybe_add_line_payee_names(fields, _transaction), do: fields
end
