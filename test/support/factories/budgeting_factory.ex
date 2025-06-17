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

  def category_factory(attrs) do
    name = Map.get(attrs, :name, Faker.Industry.industry())

    category =
      %Category{}
      |> Category.changeset(%{
        name: name,
        position: sequence(:category_position, &generate_lowercase_position/1)
      })
      |> Ecto.Changeset.apply_changes()

    category
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  def envelope_factory(attrs) do
    name = Map.get(attrs, :name, Faker.Commerce.product_name())
    position = Map.get(attrs, :position, sequence(:envelope_position, &generate_lowercase_position/1))

    envelope =
      %Envelope{}
      |> Envelope.changeset(%{name: name, position: position})
      |> Ecto.Changeset.apply_changes()

    envelope
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  def user_factory do
    %User{
      email: valid_email()
    }
  end

  defp generate_lowercase_position(1), do: "m"

  defp generate_lowercase_position(n) when n <= 26 do
    if rem(n, 2) == 1 do
      offset = div(n - 1, 2)
      char_code = ?m + offset

      if char_code <= ?z do
        <<char_code>>
      else
        "ma"
      end
    else
      offset = div(n, 2)
      char_code = ?m - offset

      if char_code >= ?a do
        <<char_code>>
      else
        "mb"
      end
    end
  end

  defp generate_lowercase_position(n) do
    second_offset = rem(n - 27, 26)
    "m" <> <<?a + second_offset>>
  end
end
