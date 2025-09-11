defmodule PurseCraft.AccountingFactory do
  @moduledoc false

  use PurseCraft.FactoryTemplate

  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Accounting.Schemas.Payee
  alias PurseCraft.Accounting.Schemas.Transaction
  alias PurseCraft.Accounting.Schemas.TransactionLine
  alias PurseCraft.TestHelpers.PositionHelper

  def account_factory(attrs) do
    name = Map.get(attrs, :name, Faker.Company.name() <> " Account")
    account_type = Map.get(attrs, :account_type, Enum.random(Account.account_types()))
    description = Map.get(attrs, :description, Faker.Lorem.sentence())

    account =
      %Account{}
      |> Account.create_changeset(%{
        name: name,
        account_type: account_type,
        description: description,
        position: sequence(:account_position, &PositionHelper.generate_lowercase_position/1)
      })
      |> Ecto.Changeset.apply_changes()

    account
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  def payee_factory(attrs) do
    name = Map.get(attrs, :name, Faker.Company.name())

    payee =
      %Payee{}
      |> Payee.changeset(%{name: name})
      |> Ecto.Changeset.apply_changes()

    payee
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  def transaction_factory(attrs) do
    date = Map.get(attrs, :date, Date.utc_today())
    amount = Map.get(attrs, :amount, Enum.random(-10_000..-100))
    memo = Map.get(attrs, :memo, Faker.Lorem.sentence())
    cleared = Map.get(attrs, :cleared, false)

    transaction =
      %Transaction{}
      |> Transaction.changeset(%{
        date: date,
        amount: amount,
        memo: memo,
        cleared: cleared
      })
      |> Ecto.Changeset.apply_changes()

    transaction
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  def transaction_line_factory(attrs) do
    amount = Map.get(attrs, :amount, Enum.random(100..10_000))
    memo = Map.get(attrs, :memo, nil)

    transaction_line =
      %TransactionLine{}
      |> TransactionLine.changeset(%{
        amount: amount,
        memo: memo
      })
      |> Ecto.Changeset.apply_changes()

    transaction_line
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end
end
