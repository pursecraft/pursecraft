defmodule PurseCraft.BudgetingFactory do
  @moduledoc false

  use PurseCraft.FactoryTemplate

  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Budgeting.Schemas.BookUser
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.Budgeting.Schemas.User

  def book_factory do
    %Book{
      name: Faker.Pokemon.name()
    }
  end

  def book_user_factory do
    %BookUser{
      role: Enum.random([:owner, :editor, :commenter])
    }
  end

  def category_factory do
    %Category{
      name: Faker.Industry.industry()
    }
  end

  def envelope_factory do
    %Envelope{
      name: Faker.Commerce.product_name()
    }
  end

  def user_factory do
    %User{
      email: valid_email()
    }
  end
end
