defmodule PurseCraft.Budgeting.Repositories.EnvelopeRepositoryTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting.Repositories.EnvelopeRepository
  alias PurseCraft.BudgetingFactory

  describe "create/1" do
    test "with valid data creates an envelope" do
      book = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      attrs = %{name: "Test Envelope", category_id: category.id}

      assert {:ok, envelope} = EnvelopeRepository.create(attrs)
      assert envelope.name == "Test Envelope"
      assert envelope.category_id == category.id
    end

    test "with invalid data returns error changeset" do
      attrs = %{name: ""}

      assert {:error, changeset} = EnvelopeRepository.create(attrs)
      assert %{name: ["can't be blank"], category_id: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "delete/1" do
    test "deletes an envelope" do
      book = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      assert {:ok, deleted_envelope} = EnvelopeRepository.delete(envelope)
      assert deleted_envelope.id == envelope.id
    end
  end
end
