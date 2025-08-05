defmodule PurseCraft.Accounting.Repositories.PayeeRepositoryTest do
  use PurseCraft.DataCase, async: true

  alias Ecto.Association.NotLoaded
  alias PurseCraft.Accounting.Repositories.PayeeRepository
  alias PurseCraft.Accounting.Schemas.Payee
  alias PurseCraft.AccountingFactory
  alias PurseCraft.CoreFactory

  setup do
    workspace = CoreFactory.insert(:workspace)
    {:ok, workspace: workspace}
  end

  describe "create/1" do
    test "with valid attributes creates a payee", %{workspace: workspace} do
      attrs = %{
        name: "Grocery Store",
        workspace_id: workspace.id
      }

      assert {:ok, %Payee{} = payee} = PayeeRepository.create(attrs)
      assert payee.name == "Grocery Store"
      assert payee.workspace_id == workspace.id
      assert is_binary(payee.external_id)
      assert is_binary(payee.name_hash)
    end

    test "with invalid name returns error changeset", %{workspace: workspace} do
      attrs = %{
        name: "",
        workspace_id: workspace.id
      }

      assert {:error, changeset} = PayeeRepository.create(attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with nil name returns error changeset", %{workspace: workspace} do
      attrs = %{
        name: nil,
        workspace_id: workspace.id
      }

      assert {:error, changeset} = PayeeRepository.create(attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with missing required fields returns error changeset" do
      attrs = %{name: "Grocery Store"}

      assert {:error, changeset} = PayeeRepository.create(attrs)
      assert %{workspace_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "enforces workspace_id + name_hash unique constraint", %{workspace: workspace} do
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Grocery Store")

      attrs = %{
        name: "Grocery Store",
        workspace_id: workspace.id
      }

      assert {:error, changeset} = PayeeRepository.create(attrs)
      assert %{name_hash: ["has already been taken"]} = errors_on(changeset)
    end

    test "allows same name in different workspaces" do
      workspace1 = CoreFactory.insert(:workspace)
      workspace2 = CoreFactory.insert(:workspace)
      AccountingFactory.insert(:payee, workspace_id: workspace1.id, name: "Grocery Store")

      attrs = %{
        name: "Grocery Store",
        workspace_id: workspace2.id
      }

      assert {:ok, %Payee{}} = PayeeRepository.create(attrs)
    end

    test "handles long payee names", %{workspace: workspace} do
      long_name = String.duplicate("A", 255)

      attrs = %{
        name: long_name,
        workspace_id: workspace.id
      }

      assert {:ok, %Payee{} = payee} = PayeeRepository.create(attrs)
      assert payee.name == long_name
    end

    test "handles special characters in payee names", %{workspace: workspace} do
      special_name = "Café & Bakery (André's)"

      attrs = %{
        name: special_name,
        workspace_id: workspace.id
      }

      assert {:ok, %Payee{} = payee} = PayeeRepository.create(attrs)
      assert payee.name == special_name
    end
  end

  describe "delete/1" do
    test "with valid payee deletes successfully", %{workspace: workspace} do
      payee = AccountingFactory.insert(:payee, workspace_id: workspace.id)

      assert {:ok, deleted_payee} = PayeeRepository.delete(payee)
      assert deleted_payee.id == payee.id

      assert PayeeRepository.get_by_external_id(payee.external_id) == nil
    end

    test "with already deleted payee returns error", %{workspace: workspace} do
      payee = AccountingFactory.insert(:payee, workspace_id: workspace.id)

      assert {:ok, _deleted_payee} = PayeeRepository.delete(payee)

      assert {:error, changeset} = PayeeRepository.delete(payee)
      assert changeset.errors[:id] == {"is stale", [stale: true]}
    end

    test "deleting payee with stale struct returns error", %{workspace: workspace} do
      payee = AccountingFactory.insert(:payee, workspace_id: workspace.id)
      stale_payee = %{payee | id: payee.id + 1}

      assert {:error, changeset} = PayeeRepository.delete(stale_payee)
      assert changeset.errors[:id] == {"is stale", [stale: true]}
    end
  end

  describe "get_by_external_id/2" do
    test "returns payee when found", %{workspace: workspace} do
      payee = AccountingFactory.insert(:payee, workspace_id: workspace.id)

      result = PayeeRepository.get_by_external_id(payee.external_id)

      assert result.id == payee.id
      assert result.external_id == payee.external_id
      assert result.name == payee.name
    end

    test "returns nil when payee not found" do
      result = PayeeRepository.get_by_external_id(Ecto.UUID.generate())

      assert result == nil
    end

    test "returns payee with preloaded associations", %{workspace: workspace} do
      payee = AccountingFactory.insert(:payee, workspace_id: workspace.id)

      result = PayeeRepository.get_by_external_id(payee.external_id, preload: [:workspace])

      assert result.id == payee.id
      assert %NotLoaded{} != result.workspace
      assert result.workspace.id == payee.workspace_id
    end

    test "returns payee without preload when no preload option given", %{workspace: workspace} do
      payee = AccountingFactory.insert(:payee, workspace_id: workspace.id)

      result = PayeeRepository.get_by_external_id(payee.external_id)

      assert result.id == payee.id
      assert %NotLoaded{} = result.workspace
    end

    test "handles invalid external_id gracefully" do
      result = PayeeRepository.get_by_external_id(Ecto.UUID.generate())

      assert result == nil
    end
  end

  describe "get_by_name/3" do
    test "returns payee when found by exact name match", %{workspace: workspace} do
      payee = AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Grocery Store")

      result = PayeeRepository.get_by_name(workspace, "Grocery Store")

      assert result.id == payee.id
      assert result.name == "Grocery Store"
    end

    test "returns nil when payee not found", %{workspace: workspace} do
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Grocery Store")

      result = PayeeRepository.get_by_name(workspace, "Non-existent Store")

      assert result == nil
    end

    test "returns payee with preloaded associations", %{workspace: workspace} do
      payee = AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Grocery Store")

      result = PayeeRepository.get_by_name(workspace, "Grocery Store", preload: [:workspace])

      assert result.id == payee.id
      assert %NotLoaded{} != result.workspace
      assert result.workspace.id == workspace.id
    end

    test "returns payee without preload when no preload option given", %{workspace: workspace} do
      payee = AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Grocery Store")

      result = PayeeRepository.get_by_name(workspace, "Grocery Store")

      assert result.id == payee.id
      assert %NotLoaded{} = result.workspace
    end

    test "is case sensitive for name matching", %{workspace: workspace} do
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Grocery Store")

      result = PayeeRepository.get_by_name(workspace, "grocery store")

      assert result == nil
    end

    test "only returns payees from specified workspace", %{workspace: workspace} do
      other_workspace = CoreFactory.insert(:workspace)
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Grocery Store")
      AccountingFactory.insert(:payee, workspace_id: other_workspace.id, name: "Grocery Store")

      result = PayeeRepository.get_by_name(workspace, "Grocery Store")

      assert result.workspace_id == workspace.id
    end

    test "handles special characters in name", %{workspace: workspace} do
      special_name = "Café & Bakery (André's)"
      payee = AccountingFactory.insert(:payee, workspace_id: workspace.id, name: special_name)

      result = PayeeRepository.get_by_name(workspace, special_name)

      assert result.id == payee.id
      assert result.name == special_name
    end

    test "uses name_hash for exact matching with encryption", %{workspace: workspace} do
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Test Store")

      result = PayeeRepository.get_by_name(workspace, "Test Store")

      assert result != nil
      assert result.name == "Test Store"
    end
  end

  describe "list_by_workspace/2" do
    test "returns all payees for a workspace ordered by name", %{workspace: workspace} do
      payee1 = AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Zebra Store")
      payee2 = AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Apple Store")
      payee3 = AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Beta Store")

      result = PayeeRepository.list_by_workspace(workspace)

      assert length(result) == 3
      result_ids = Enum.map(result, & &1.id)
      expected_ids = [payee1.id, payee2.id, payee3.id]
      assert Enum.sort(result_ids) == Enum.sort(expected_ids)
      names = Enum.map(result, & &1.name)
      assert "Zebra Store" in names
      assert "Apple Store" in names
      assert "Beta Store" in names
    end

    test "returns empty list when no payees exist", %{workspace: workspace} do
      result = PayeeRepository.list_by_workspace(workspace)

      assert result == []
    end

    test "returns payees with preloaded associations", %{workspace: workspace} do
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Test Store")

      result = PayeeRepository.list_by_workspace(workspace, preload: [:workspace])

      assert [payee] = result
      assert %NotLoaded{} != payee.workspace
      assert payee.workspace.id == workspace.id
    end

    test "returns payees without preload when no preload option given", %{workspace: workspace} do
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Test Store")

      result = PayeeRepository.list_by_workspace(workspace)

      assert [payee] = result
      assert %NotLoaded{} = payee.workspace
    end

    test "only returns payees for specified workspace", %{workspace: workspace} do
      other_workspace = CoreFactory.insert(:workspace)
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Store A")
      AccountingFactory.insert(:payee, workspace_id: other_workspace.id, name: "Store B")

      result = PayeeRepository.list_by_workspace(workspace)

      assert length(result) == 1
      assert [payee] = result
      assert payee.workspace_id == workspace.id
      assert payee.name == "Store A"
    end

    test "limits results when limit option provided", %{workspace: workspace} do
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Store A")
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Store B")
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Store C")

      result = PayeeRepository.list_by_workspace(workspace, limit: 2)

      assert length(result) == 2
    end

    test "handles multiple options together", %{workspace: workspace} do
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Store A")
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Store B")
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Store C")

      result = PayeeRepository.list_by_workspace(workspace, preload: [:workspace], limit: 2)

      assert length(result) == 2
      assert [first, second] = result
      assert %NotLoaded{} != first.workspace
      assert %NotLoaded{} != second.workspace
    end

    test "handles workspace with no payees returns empty list" do
      non_existent_workspace = %PurseCraft.Core.Schemas.Workspace{id: 999_999}

      result = PayeeRepository.list_by_workspace(non_existent_workspace)

      assert result == []
    end

    test "orders payees consistently by encrypted name", %{workspace: workspace} do
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "McDonald's")
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Amazon")
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Walmart")
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Target")

      result = PayeeRepository.list_by_workspace(workspace)

      assert length(result) == 4
      names = Enum.map(result, & &1.name)
      assert "McDonald's" in names
      assert "Amazon" in names
      assert "Walmart" in names
      assert "Target" in names

      result2 = PayeeRepository.list_by_workspace(workspace)
      names2 = Enum.map(result2, & &1.name)
      assert names == names2
    end

    test "handles special characters in ordering", %{workspace: workspace} do
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Ñoño's Store")
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Apple Store")
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Zebra Store")

      result = PayeeRepository.list_by_workspace(workspace)

      assert length(result) == 3
      names = Enum.map(result, & &1.name)
      assert "Apple Store" in names
      assert "Ñoño's Store" in names
      assert "Zebra Store" in names
    end

    test "handles empty limit gracefully", %{workspace: workspace} do
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Store A")

      result = PayeeRepository.list_by_workspace(workspace, limit: 0)

      assert result == []
    end
  end
end
