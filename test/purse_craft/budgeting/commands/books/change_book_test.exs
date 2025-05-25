defmodule PurseCraft.Budgeting.Commands.Books.ChangeBookTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting.Commands.Books.ChangeBook
  alias PurseCraft.BudgetingFactory

  describe "call/2" do
    test "returns a book changeset" do
      book = BudgetingFactory.insert(:book)

      assert %Ecto.Changeset{} = changeset = ChangeBook.call(book, %{})
      assert changeset.data == book
      assert changeset.changes == %{}
    end

    test "returns a book changeset with changes" do
      book = BudgetingFactory.insert(:book)
      new_name = "New Book Name"

      assert %Ecto.Changeset{} = changeset = ChangeBook.call(book, %{name: new_name})
      assert changeset.data == book
      assert changeset.changes == %{name: new_name}
    end
  end
end
