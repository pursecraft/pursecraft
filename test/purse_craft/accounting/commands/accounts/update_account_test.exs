defmodule PurseCraft.Accounting.Commands.Accounts.UpdateAccountTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Accounting.Commands.Accounts.UpdateAccount
  alias PurseCraft.AccountingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

  setup do
    user = IdentityFactory.insert(:user)
    workspace = CoreFactory.insert(:workspace)
    scope = IdentityFactory.build(:scope, user: user)

    {:ok, user: user, workspace: workspace, scope: scope}
  end

  describe "call/4" do
    test "with owner role (authorized scope) updates account successfully", %{
      user: user,
      scope: scope,
      workspace: workspace
    } do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      account = AccountingFactory.insert(:account, workspace: workspace, name: "Old Name", description: "Old Description")
      attrs = %{name: "New Name", description: "New Description"}

      assert {:ok, updated_account} = UpdateAccount.call(scope, workspace, account.external_id, attrs)
      assert updated_account.name == "New Name"
      assert updated_account.description == "New Description"
      assert updated_account.account_type == account.account_type
    end

    test "with editor role (authorized scope) updates account successfully", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)
      account = AccountingFactory.insert(:account, workspace: workspace, name: "Old Name")
      attrs = %{name: "New Name"}

      assert {:ok, updated_account} = UpdateAccount.call(scope, workspace, account.external_id, attrs)
      assert updated_account.name == "New Name"
    end

    test "with commenter role (unauthorized scope) returns error", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)
      account = AccountingFactory.insert(:account, workspace: workspace)
      attrs = %{name: "New Name"}

      assert {:error, :unauthorized} = UpdateAccount.call(scope, workspace, account.external_id, attrs)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      account = AccountingFactory.insert(:account, workspace: workspace)
      attrs = %{name: "New Name"}

      assert {:error, :unauthorized} = UpdateAccount.call(scope, workspace, account.external_id, attrs)
    end

    test "with invalid external_id returns not found error", %{user: user, scope: scope, workspace: workspace} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      attrs = %{name: "New Name"}

      assert {:error, :not_found} = UpdateAccount.call(scope, workspace, Ecto.UUID.generate(), attrs)
    end

    test "with invalid attributes returns changeset error", %{user: user, scope: scope, workspace: workspace} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      account = AccountingFactory.insert(:account, workspace: workspace)
      attrs = %{name: ""}

      assert {:error, changeset} = UpdateAccount.call(scope, workspace, account.external_id, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "ignores account_type changes silently", %{user: user, scope: scope, workspace: workspace} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      account = AccountingFactory.insert(:account, workspace: workspace, account_type: "checking")
      attrs = %{name: "New Name", account_type: "savings"}

      assert {:ok, updated_account} = UpdateAccount.call(scope, workspace, account.external_id, attrs)
      assert updated_account.name == "New Name"
      assert updated_account.account_type == "checking"
    end
  end
end
