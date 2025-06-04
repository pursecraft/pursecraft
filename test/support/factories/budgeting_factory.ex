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
      name: Faker.Industry.industry(),
      position: sequence(:category_position, &generate_lowercase_position/1)
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

  defp generate_lowercase_position(n) when n <= 26 do
    <<?a + n - 1>>
  end

  defp generate_lowercase_position(n) do
    # For n > 26, generate aa, ab, ac, etc.
    first = div(n - 27, 26)
    second = rem(n - 27, 26)
    <<?a + first, ?a + second>>
  end
end
