defmodule PurseCraft.BudgetingFactory do
  @moduledoc false

  use PurseCraft.FactoryTemplate

  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.TestHelpers.PositionHelper

  def category_factory(attrs) do
    name = Map.get(attrs, :name, Faker.Industry.industry())
    position = Map.get(attrs, :position, PositionHelper.generate_lowercase_position())

    category =
      %Category{}
      |> Category.changeset(%{
        name: name,
        position: position
      })
      |> Ecto.Changeset.apply_changes()

    category
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  def envelope_factory(attrs) do
    name = Map.get(attrs, :name, Faker.Commerce.product_name())
    position = Map.get(attrs, :position, PositionHelper.generate_lowercase_position())

    envelope =
      %Envelope{}
      |> Envelope.changeset(%{name: name, position: position})
      |> Ecto.Changeset.apply_changes()

    envelope
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end
end
