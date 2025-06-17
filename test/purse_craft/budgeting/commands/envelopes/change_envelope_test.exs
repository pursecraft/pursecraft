defmodule PurseCraft.Budgeting.Commands.Envelopes.ChangeEnvelopeTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting.Commands.Envelopes.ChangeEnvelope
  alias PurseCraft.BudgetingFactory

  describe "call/2" do
    test "returns an envelope changeset" do
      book = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      assert %Ecto.Changeset{} = changeset = ChangeEnvelope.call(envelope, %{})
      assert changeset.data == envelope
      assert changeset.changes == %{}
    end

    test "returns an envelope changeset with changes" do
      book = BudgetingFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)
      new_name = "New Envelope Name"

      assert %Ecto.Changeset{} = changeset = ChangeEnvelope.call(envelope, %{name: new_name})
      assert changeset.data == envelope
      assert changeset.changes == %{name: new_name, name_hash: new_name}
    end
  end
end
