defmodule PurseCraft.AccountingFactory do
  @moduledoc false

  use PurseCraft.FactoryTemplate

  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Accounting.Schemas.Payee
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
end
