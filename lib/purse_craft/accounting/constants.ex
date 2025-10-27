defmodule PurseCraft.Accounting.Constants do
  @moduledoc """
  Constants for the Accounting context.

  This module defines all constants used throughout the Accounting context,
  serving as the single source of truth for values like account types.

  It has no dependencies on other modules, making it safe to import anywhere
  without creating circular dependencies.
  """

  @asset_account_types ["checking", "savings", "cash", "asset"]
  @liability_account_types [
    "credit_card",
    "line_of_credit",
    "mortgage",
    "auto_loan",
    "student_loan",
    "personal_loan",
    "medical_debt",
    "other_debt",
    "liability"
  ]

  @doc """
  Returns the list of all asset account types.

  Asset accounts have normal debit balances - increases are positive,
  decreases are negative.

  ## Examples

      iex> asset_account_types()
      ["checking", "savings", "cash", "asset"]

  """
  @spec asset_account_types() :: [String.t()]
  def asset_account_types, do: @asset_account_types

  @doc """
  Returns the list of all liability account types.

  Liability accounts have normal credit balances - increases are negative,
  decreases are positive.

  ## Examples

      iex> liability_account_types()
      ["credit_card", "line_of_credit", ...]

  """
  @spec liability_account_types() :: [String.t()]
  def liability_account_types, do: @liability_account_types

  @doc """
  Returns the complete list of all valid account types.

  This combines both asset and liability account types.

  ## Examples

      iex> all_account_types()
      ["checking", "savings", "cash", "asset", "credit_card", ...]

  """
  @spec all_account_types() :: [String.t()]
  def all_account_types, do: @asset_account_types ++ @liability_account_types
end
