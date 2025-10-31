defmodule PurseCraft.Accounting.Repositories.AccountRepositoryTest do
  use PurseCraft.DataCase, async: true

  alias Ecto.Association.NotLoaded
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.AccountingFactory
  alias PurseCraft.CoreFactory

  setup do
    workspace = CoreFactory.insert(:workspace)
    {:ok, workspace: workspace}
  end

  describe "create/1" do
    test "with valid attributes creates an account", %{workspace: workspace} do
      attrs = %{
        name: "Test Account",
        account_type: "checking",
        description: "Test Description",
        workspace_id: workspace.id,
        position: "m"
      }

      assert {:ok, %Account{} = account} = AccountRepository.create(attrs)
      assert account.name == "Test Account"
      assert account.account_type == "checking"
      assert account.description == "Test Description"
      assert account.workspace_id == workspace.id
      assert account.position == "m"
      assert is_binary(account.external_id)
    end

    test "with invalid name returns error changeset", %{workspace: workspace} do
      attrs = %{
        name: "",
        account_type: "checking",
        workspace_id: workspace.id,
        position: "m"
      }

      assert {:error, changeset} = AccountRepository.create(attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with invalid account_type returns error changeset", %{workspace: workspace} do
      attrs = %{
        name: "Test Account",
        account_type: "invalid_type",
        workspace_id: workspace.id,
        position: "m"
      }

      assert {:error, changeset} = AccountRepository.create(attrs)
      assert %{account_type: ["is invalid"]} = errors_on(changeset)
    end

    test "with missing required fields returns error changeset" do
      attrs = %{name: "Test Account"}

      assert {:error, changeset} = AccountRepository.create(attrs)
      assert %{workspace_id: ["can't be blank"], position: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates position format", %{workspace: workspace} do
      attrs = %{
        name: "Test Account",
        account_type: "checking",
        workspace_id: workspace.id,
        position: "INVALID"
      }

      assert {:error, changeset} = AccountRepository.create(attrs)
      assert %{position: ["must contain only lowercase letters"]} = errors_on(changeset)
    end

    test "enforces workspace_id + position unique constraint", %{workspace: workspace} do
      AccountingFactory.insert(:account, workspace: workspace, position: "m")

      attrs = %{
        name: "Duplicate Position Account",
        account_type: "checking",
        workspace_id: workspace.id,
        position: "m"
      }

      assert {:error, changeset} = AccountRepository.create(attrs)
      assert %{position: ["has already been taken"]} = errors_on(changeset)
    end

    test "allows same position in different workspaces" do
      workspace1 = CoreFactory.insert(:workspace)
      workspace2 = CoreFactory.insert(:workspace)
      AccountingFactory.insert(:account, workspace: workspace1, position: "m")

      attrs = %{
        name: "Same Position Different Workspace",
        account_type: "checking",
        workspace_id: workspace2.id,
        position: "m"
      }

      assert {:ok, %Account{}} = AccountRepository.create(attrs)
    end
  end

  describe "get_first_position/1" do
    test "returns nil when no accounts exist in workspace", %{workspace: workspace} do
      assert AccountRepository.get_first_position(workspace.id) == nil
    end

    test "returns position of first account when accounts exist", %{workspace: workspace} do
      AccountingFactory.insert(:account, workspace: workspace, position: "m")
      AccountingFactory.insert(:account, workspace: workspace, position: "g")
      AccountingFactory.insert(:account, workspace: workspace, position: "t")

      assert AccountRepository.get_first_position(workspace.id) == "g"
    end

    test "returns single account position when only one account exists", %{workspace: workspace} do
      AccountingFactory.insert(:account, workspace: workspace, position: "m")

      assert AccountRepository.get_first_position(workspace.id) == "m"
    end

    test "ignores accounts from other workspaces", %{workspace: workspace} do
      other_workspace = CoreFactory.insert(:workspace)
      AccountingFactory.insert(:account, workspace: workspace, position: "a")
      AccountingFactory.insert(:account, workspace: other_workspace, position: "z")

      assert AccountRepository.get_first_position(workspace.id) == "a"
      assert AccountRepository.get_first_position(other_workspace.id) == "z"
    end

    test "handles complex position ordering correctly", %{workspace: workspace} do
      AccountingFactory.insert(:account, workspace: workspace, position: "m")
      AccountingFactory.insert(:account, workspace: workspace, position: "d")
      AccountingFactory.insert(:account, workspace: workspace, position: "g")
      AccountingFactory.insert(:account, workspace: workspace, position: "b")
      AccountingFactory.insert(:account, workspace: workspace, position: "t")

      assert AccountRepository.get_first_position(workspace.id) == "b"
    end
  end

  describe "get_by_external_id/2" do
    test "returns account when found", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace)

      result = AccountRepository.get_by_external_id(account.external_id)

      assert result.id == account.id
      assert result.external_id == account.external_id
    end

    test "returns nil when account not found" do
      result = AccountRepository.get_by_external_id(Ecto.UUID.generate())

      assert result == nil
    end

    test "returns account with preloaded associations", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace)

      result = AccountRepository.get_by_external_id(account.external_id, preload: [:workspace])

      assert result.id == account.id
      assert %NotLoaded{} != result.workspace
      assert result.workspace.id == account.workspace_id
    end

    test "filters closed accounts when active_only is true (default)", %{workspace: workspace} do
      closed_account = AccountingFactory.insert(:account, workspace: workspace, closed_at: DateTime.utc_now())

      result = AccountRepository.get_by_external_id(closed_account.external_id)

      assert result == nil
    end

    test "includes closed accounts when active_only is false", %{workspace: workspace} do
      closed_account = AccountingFactory.insert(:account, workspace: workspace, closed_at: DateTime.utc_now())

      result = AccountRepository.get_by_external_id(closed_account.external_id, active_only: false)

      assert result.id == closed_account.id
    end
  end

  describe "list_by_workspace/2" do
    test "returns all accounts for a workspace ordered by position", %{workspace: workspace} do
      account1 = AccountingFactory.insert(:account, workspace: workspace, position: "bbbb")
      account2 = AccountingFactory.insert(:account, workspace: workspace, position: "aaaa")
      account3 = AccountingFactory.insert(:account, workspace: workspace, position: "cccc")

      result = AccountRepository.list_by_workspace(workspace.id)

      assert length(result) == 3
      assert [first, second, third] = result
      assert first.id == account2.id
      assert second.id == account1.id
      assert third.id == account3.id
    end

    test "returns empty list when no accounts exist", %{workspace: workspace} do
      result = AccountRepository.list_by_workspace(workspace.id)

      assert result == []
    end

    test "returns accounts with preloaded associations", %{workspace: workspace} do
      AccountingFactory.insert(:account, workspace: workspace)

      result = AccountRepository.list_by_workspace(workspace.id, preload: [:workspace])

      assert [account] = result
      assert %NotLoaded{} != account.workspace
      assert account.workspace.id == workspace.id
    end

    test "filters closed accounts when active_only is true (default)", %{workspace: workspace} do
      AccountingFactory.insert(:account, workspace: workspace)
      AccountingFactory.insert(:account, workspace: workspace, closed_at: DateTime.utc_now())

      result = AccountRepository.list_by_workspace(workspace.id)

      assert length(result) == 1
    end

    test "includes closed accounts when active_only is false", %{workspace: workspace} do
      active_account = AccountingFactory.insert(:account, workspace: workspace)

      closed_account =
        AccountingFactory.insert(:account, workspace: workspace, closed_at: DateTime.utc_now())

      result = AccountRepository.list_by_workspace(workspace.id, active_only: false)

      assert length(result) == 2
      assert [first, second] = result
      assert first.id == active_account.id
      assert second.id == closed_account.id
    end

    test "only returns accounts for specified workspace", %{workspace: workspace} do
      other_workspace = CoreFactory.insert(:workspace)
      AccountingFactory.insert(:account, workspace: workspace)
      AccountingFactory.insert(:account, workspace: other_workspace)

      result = AccountRepository.list_by_workspace(workspace.id)

      assert length(result) == 1
      assert [account] = result
      assert account.workspace_id == workspace.id
    end

    test "handles multiple options together", %{workspace: workspace} do
      active_account = AccountingFactory.insert(:account, workspace: workspace)
      AccountingFactory.insert(:account, workspace: workspace, closed_at: DateTime.utc_now())

      result = AccountRepository.list_by_workspace(workspace.id, preload: [:workspace], active_only: true)

      assert length(result) == 1
      assert [account] = result
      assert account.id == active_account.id
      assert %NotLoaded{} != account.workspace
    end

    test "handles workspace with no accounts returns empty list" do
      non_existent_workspace_id = 999_999

      result = AccountRepository.list_by_workspace(non_existent_workspace_id)

      assert result == []
    end
  end

  describe "update/2" do
    test "with valid attributes updates an account", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace, name: "Old Name", description: "Old Description")
      attrs = %{name: "New Name", description: "New Description"}

      assert {:ok, %Account{} = updated_account} = AccountRepository.update(account, attrs)
      assert updated_account.id == account.id
      assert updated_account.name == "New Name"
      assert updated_account.description == "New Description"
      assert updated_account.account_type == account.account_type
      assert updated_account.position == account.position
      assert updated_account.workspace_id == account.workspace_id
    end

    test "with invalid name returns error changeset", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace)
      attrs = %{name: ""}

      assert {:error, changeset} = AccountRepository.update(account, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with empty description updates successfully", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace, description: "Old Description")
      attrs = %{description: ""}

      assert {:ok, updated_account} = AccountRepository.update(account, attrs)
      assert updated_account.description == nil
    end

    test "with nil attributes handles gracefully", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace, name: "Original Name")
      attrs = %{name: nil}

      assert {:error, changeset} = AccountRepository.update(account, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "ignores account_type changes", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace, account_type: "checking")
      attrs = %{account_type: "savings", name: "Updated Name"}

      assert {:ok, updated_account} = AccountRepository.update(account, attrs)
      assert updated_account.account_type == "checking"
      assert updated_account.name == "Updated Name"
    end

    test "ignores position changes", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace, position: "m")
      attrs = %{position: "z", name: "Updated Name"}

      assert {:ok, updated_account} = AccountRepository.update(account, attrs)
      assert updated_account.position == "m"
      assert updated_account.name == "Updated Name"
    end

    test "ignores workspace_id changes", %{workspace: workspace} do
      other_workspace = CoreFactory.insert(:workspace)
      account = AccountingFactory.insert(:account, workspace: workspace)
      attrs = %{workspace_id: other_workspace.id, name: "Updated Name"}

      assert {:ok, updated_account} = AccountRepository.update(account, attrs)
      assert updated_account.workspace_id == workspace.id
      assert updated_account.name == "Updated Name"
    end

    test "ignores external_id changes", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace)
      original_external_id = account.external_id
      attrs = %{external_id: Ecto.UUID.generate(), name: "Updated Name"}

      assert {:ok, updated_account} = AccountRepository.update(account, attrs)
      assert updated_account.external_id == original_external_id
      assert updated_account.name == "Updated Name"
    end
  end

  describe "delete/1" do
    test "with valid account deletes successfully", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace)

      assert {:ok, deleted_account} = AccountRepository.delete(account)
      assert deleted_account.id == account.id

      assert AccountRepository.get_by_external_id(account.external_id, active_only: false) == nil
    end

    test "with already deleted account returns error", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace)

      assert {:ok, _deleted_account} = AccountRepository.delete(account)

      assert {:error, changeset} = AccountRepository.delete(account)
      assert changeset.errors[:id] == {"is stale", [stale: true]}
    end
  end

  describe "close/1" do
    test "with valid account closes successfully", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace, closed_at: nil)

      assert {:ok, closed_account} = AccountRepository.close(account)
      assert closed_account.id == account.id
      assert closed_account.closed_at != nil
    end

    test "verifies closed account persists in database", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace, closed_at: nil)

      assert {:ok, closed_account} = AccountRepository.close(account)

      retrieved_account = AccountRepository.get_by_external_id(account.external_id, active_only: false)
      assert retrieved_account != nil
      assert retrieved_account.closed_at == closed_account.closed_at
    end
  end

  describe "update_position/2" do
    test "with valid position updates successfully", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace, position: "m")

      assert {:ok, updated_account} = AccountRepository.update_position(account, "z")
      assert updated_account.id == account.id
      assert updated_account.position == "z"
    end

    test "with invalid position returns error changeset", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace, position: "m")

      assert {:error, changeset} = AccountRepository.update_position(account, "INVALID")
      assert %{position: ["must contain only lowercase letters"]} = errors_on(changeset)
    end

    test "with duplicate position returns unique constraint error", %{workspace: workspace} do
      AccountingFactory.insert(:account, workspace: workspace, position: "g")
      account2 = AccountingFactory.insert(:account, workspace: workspace, position: "m")

      assert {:error, changeset} = AccountRepository.update_position(account2, "g")
      assert %{position: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "list_by_external_ids/2" do
    test "returns accounts matching the external IDs", %{workspace: workspace} do
      account1 = AccountingFactory.insert(:account, workspace: workspace, position: "g")
      account2 = AccountingFactory.insert(:account, workspace: workspace, position: "m")
      account3 = AccountingFactory.insert(:account, workspace: workspace, position: "t")

      external_ids = [account1.external_id, account3.external_id]
      result = AccountRepository.list_by_external_ids(external_ids)

      assert length(result) == 2
      returned_ids = Enum.map(result, & &1.external_id)
      assert account1.external_id in returned_ids
      assert account3.external_id in returned_ids
      refute account2.external_id in returned_ids
    end

    test "returns empty list when no external IDs match", %{workspace: workspace} do
      AccountingFactory.insert(:account, workspace: workspace)

      external_ids = [Ecto.UUID.generate(), Ecto.UUID.generate()]
      result = AccountRepository.list_by_external_ids(external_ids)

      assert result == []
    end

    test "returns accounts with preloaded associations", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace)

      result = AccountRepository.list_by_external_ids([account.external_id], preload: [:workspace])

      assert [loaded_account] = result
      assert %NotLoaded{} != loaded_account.workspace
      assert loaded_account.workspace.id == workspace.id
    end

    test "handles empty external IDs list", %{workspace: workspace} do
      AccountingFactory.insert(:account, workspace: workspace)

      result = AccountRepository.list_by_external_ids([])

      assert result == []
    end

    test "handles duplicate external IDs", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace)

      external_ids = [account.external_id, account.external_id]
      result = AccountRepository.list_by_external_ids(external_ids)

      assert length(result) == 1
      assert [returned_account] = result
      assert returned_account.id == account.id
    end
  end
end
