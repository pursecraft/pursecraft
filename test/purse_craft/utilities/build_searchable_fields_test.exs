defmodule PurseCraft.Utilities.BuildSearchableFieldsTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.AccountingFactory
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.Utilities
  alias PurseCraft.Utilities.BuildSearchableFields

  describe "call/2" do
    test "extracts valid string fields" do
      struct = %{
        name: "John Doe",
        email: "john@example.com",
        age: 30,
        active: true
      }

      result = BuildSearchableFields.call(struct, [:name, :email])

      assert result == %{
               "name" => "John Doe",
               "email" => "john@example.com"
             }
    end

    test "ignores nil values" do
      struct = %{
        name: "Active User",
        description: nil,
        notes: "Some notes"
      }

      result = BuildSearchableFields.call(struct, [:name, :description, :notes])

      assert result == %{
               "name" => "Active User",
               "notes" => "Some notes"
             }
    end

    test "ignores empty strings" do
      struct = %{
        name: "Valid Name",
        description: "",
        memo: "   ",
        notes: "Valid notes"
      }

      result = BuildSearchableFields.call(struct, [:name, :description, :memo, :notes])

      assert result == %{
               "name" => "Valid Name",
               # Whitespace-only strings are kept
               "memo" => "   ",
               "notes" => "Valid notes"
             }
    end

    test "ignores non-string values" do
      struct = %{
        name: "User Name",
        age: 25,
        balance: 100.50,
        active: true,
        tags: ["tag1", "tag2"]
      }

      result = BuildSearchableFields.call(struct, [:name, :age, :balance, :active, :tags])

      assert result == %{"name" => "User Name"}
    end

    test "handles missing fields gracefully" do
      struct = %{name: "John", email: "john@test.com"}

      result = BuildSearchableFields.call(struct, [:name, :missing_field, :another_missing])

      assert result == %{"name" => "John"}
    end

    test "works with empty field list" do
      struct = %{name: "John", email: "john@test.com"}

      result = BuildSearchableFields.call(struct, [])

      assert result == %{}
    end

    test "works with structs" do
      # Use a simple map that behaves like a struct
      struct = %{
        __struct__: SomeStruct,
        name: "Test Name",
        description: "Test Description",
        id: 123
      }

      result = BuildSearchableFields.call(struct, [:name, :description, :id])

      assert result == %{
               "name" => "Test Name",
               "description" => "Test Description"
             }
    end

    test "handles transaction-like struct" do
      transaction = %{
        memo: "Grocery shopping",
        amount: -2500,
        date: ~D[2025-01-15],
        cleared: false
      }

      result = BuildSearchableFields.call(transaction, [:memo, :amount, :date])

      assert result == %{"memo" => "Grocery shopping"}
    end
  end

  describe "integration with real entities" do
    test "works with account entities" do
      workspace = CoreFactory.insert(:workspace)
      account = AccountingFactory.insert(:account,
        workspace: workspace,
        name: "Chase Checking",
        description: "Primary checking account"
      )

      searchable_fields = Utilities.build_searchable_fields(account, [:name, :description])

      assert searchable_fields == %{
        "name" => "Chase Checking",
        "description" => "Primary checking account"
      }
    end

    test "works with payee entities" do
      workspace = CoreFactory.insert(:workspace)
      payee = AccountingFactory.insert(:payee,
        workspace: workspace,
        name: "Kroger Store"
      )

      searchable_fields = Utilities.build_searchable_fields(payee, [:name, :description])

      assert searchable_fields == %{"name" => "Kroger Store"}
    end

    test "works with envelope entities" do
      workspace = CoreFactory.insert(:workspace)
      category = BudgetingFactory.insert(:category, workspace: workspace)
      envelope = BudgetingFactory.insert(:envelope,
        category: category,
        name: "Groceries"
      )

      searchable_fields = Utilities.build_searchable_fields(envelope, [:name])

      assert searchable_fields == %{"name" => "Groceries"}
    end

    test "works with workspace entities" do
      workspace = CoreFactory.insert(:workspace, name: "Family Budget")

      searchable_fields = Utilities.build_searchable_fields(workspace, [:name])

      assert searchable_fields == %{"name" => "Family Budget"}
    end

    test "demonstrates usage across different entity types" do
      workspace = CoreFactory.insert(:workspace, name: "My Budget")
      account = AccountingFactory.insert(:account, workspace: workspace, name: "Checking", description: nil)
      payee = AccountingFactory.insert(:payee, workspace: workspace, name: "Target")

      # Different entities, same utility function
      workspace_fields = Utilities.build_searchable_fields(workspace, [:name])
      account_fields = Utilities.build_searchable_fields(account, [:name, :description])
      payee_fields = Utilities.build_searchable_fields(payee, [:name])

      assert workspace_fields == %{"name" => "My Budget"}
      assert account_fields == %{"name" => "Checking"}  # description is nil, so not included
      assert payee_fields == %{"name" => "Target"}
    end
  end
end
