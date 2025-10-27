defmodule PurseCraft.Accounting.Domain.AccountingRules do
  @moduledoc """
  Fundamental accounting rules and calculations.

  This module implements core accounting principles including account classification,
  normal balances, and double-entry transaction calculations. It serves as the
  business logic layer for accounting operations.

  Account type constants are defined in `Accounting.Constants` to avoid
  circular dependencies.

  ## Account Types and Normal Balances

  - **Asset accounts** (checking, savings, cash, asset) have **normal debit balances**:
    - Increases are recorded as positive amounts
    - Decreases are recorded as negative amounts

  - **Liability accounts** (credit cards, loans, debts) have **normal credit balances**:
    - Increases are recorded as negative amounts
    - Decreases are recorded as positive amounts

  This distinction is critical for properly calculating balances and displaying
  correct values to users in double-entry accounting systems.
  """

  alias PurseCraft.Accounting.Constants
  alias PurseCraft.Accounting.Schemas.Account

  @asset_account_types Constants.asset_account_types()
  @liability_account_types Constants.liability_account_types()

  @doc """
  Determines if an account is an asset account (normal debit balance).

  ## Examples

      iex> asset_account?(%Account{account_type: "checking"})
      true

      iex> asset_account?(%Account{account_type: "credit_card"})
      false

  """
  @spec asset_account?(Account.t()) :: boolean()
  def asset_account?(%Account{account_type: account_type}) do
    account_type in @asset_account_types
  end

  @doc """
  Determines if an account is a liability account (normal credit balance).

  ## Examples

      iex> liability_account?(%Account{account_type: "credit_card"})
      true

      iex> liability_account?(%Account{account_type: "checking"})
      false

  """
  @spec liability_account?(Account.t()) :: boolean()
  def liability_account?(%Account{account_type: account_type}) do
    account_type in @liability_account_types
  end

  @doc """
  Determines the correct transaction amount sign for a transfer based on account type
  and transfer direction.

  Accepts either an account struct or an account_type string.

  When money is transferred between accounts, the transaction amount sign depends on:
  1. The account's normal balance (asset vs liability)
  2. Whether the account is the source or destination

  ## Transfer Direction: `:source`

  The account money is leaving:
  - **Asset account**: Returns negative amount (asset decreases)
  - **Liability account**: Returns positive amount (debt decreases/paid off)

  ## Transfer Direction: `:destination`

  The account money is arriving at:
  - **Asset account**: Returns positive amount (asset increases)
  - **Liability account**: Returns negative amount (debt increases/borrowed more)

  ## Examples

  ### Asset to Asset (e.g., Checking → Savings)
      iex> transfer_amount(%{account_type: "checking"}, 10_000, :source)
      -10_000
      iex> transfer_amount(%{account_type: "savings"}, 10_000, :destination)
      10_000

  ### Asset to Liability (e.g., Checking → Credit Card - paying off debt)
      iex> transfer_amount(%{account_type: "checking"}, 10_000, :source)
      -10_000
      iex> transfer_amount(%{account_type: "credit_card"}, 10_000, :destination)
      -10_000

  ### Liability to Asset (e.g., Credit Card → Checking - cash advance)
      iex> transfer_amount(%{account_type: "credit_card"}, 10_000, :source)
      10_000
      iex> transfer_amount(%{account_type: "checking"}, 10_000, :destination)
      10_000

  ### Liability to Liability (e.g., Credit Card A → Credit Card B - balance transfer)
      iex> transfer_amount(%{account_type: "credit_card"}, 10_000, :source)
      10_000
      iex> transfer_amount(%{account_type: "line_of_credit"}, 10_000, :destination)
      -10_000

  """
  @spec transfer_amount(Account.t(), pos_integer(), :source | :destination) :: integer()
  def transfer_amount(account, amount, :source) when is_integer(amount) and amount > 0 do
    if asset_account?(account) do
      -amount
    else
      amount
    end
  end

  def transfer_amount(account, amount, :destination) when is_integer(amount) and amount > 0 do
    if asset_account?(account) do
      amount
    else
      -amount
    end
  end
end
