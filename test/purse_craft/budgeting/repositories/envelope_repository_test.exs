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

  describe "get_by_external_id_and_book_id/3" do
    test "returns envelope when found" do
      book = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      result = EnvelopeRepository.get_by_external_id_and_book_id(envelope.external_id, book.id)

      assert result.id == envelope.id
      assert result.name == envelope.name
    end

    test "returns nil when envelope not found" do
      book = BudgetingFactory.insert(:book)

      result = EnvelopeRepository.get_by_external_id_and_book_id(Ecto.UUID.generate(), book.id)

      assert result == nil
    end

    test "returns nil when envelope exists but in different book" do
      book1 = BudgetingFactory.insert(:book)
      book2 = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book1.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      result = EnvelopeRepository.get_by_external_id_and_book_id(envelope.external_id, book2.id)

      assert result == nil
    end

    test "with preload option returns envelope with preloaded associations" do
      book = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      result = EnvelopeRepository.get_by_external_id_and_book_id(envelope.external_id, book.id, preload: [:category])

      assert result.id == envelope.id
      assert result.category.id == category.id
      assert result.category.name == category.name
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
