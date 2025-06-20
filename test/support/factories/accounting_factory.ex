defmodule PurseCraft.AccountingFactory do
  @moduledoc false

  use PurseCraft.FactoryTemplate

  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Accounting.Schemas.Book
  alias PurseCraft.Accounting.Schemas.BookUser
  alias PurseCraft.TestHelpers.PositionHelper

  def book_factory do
    name = Faker.Pokemon.name()

    # Manual changeset logic for testing since accounting context doesn't manage books
    book =
      %Book{name: name, name_hash: name}
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.apply_changes()

    book
  end

  def account_factory(attrs) do
    name = Map.get(attrs, :name, Faker.Person.first_name() <> "'s " <> Faker.Commerce.product_name())
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

  def book_user_factory do
    %BookUser{
      role: :owner
    }
  end
end
