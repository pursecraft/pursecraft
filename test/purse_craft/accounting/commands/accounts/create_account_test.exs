defmodule PurseCraft.Accounting.Commands.Accounts.CreateAccountTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Accounting.Commands.Accounts.CreateAccount
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.AccountingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastWorkspace

  setup do
    workspace = CoreFactory.insert(:workspace)

    %{
      workspace: workspace
    }
  end

  describe "call/3" do
    test "with string keys in attrs creates an account correctly", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{"name" => "String Key Account", "account_type" => "checking"}

      assert {:ok, %Account{} = account} = CreateAccount.call(scope, workspace, attrs)
      assert account.name == "String Key Account"
      assert account.account_type == "checking"
      assert account.workspace_id == workspace.id
      assert account.position == "m"
    end

    test "with invalid data returns error changeset", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "", account_type: "invalid_type"}

      assert {:error, changeset} = CreateAccount.call(scope, workspace, attrs)
      assert %{name: ["can't be blank"], account_type: ["is invalid"]} = errors_on(changeset)
    end

    test "with owner role (authorized scope) creates an account", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Owner Account", account_type: "savings"}

      assert {:ok, %Account{} = account} = CreateAccount.call(scope, workspace, attrs)
      assert account.name == "Owner Account"
      assert account.account_type == "savings"
      assert account.workspace_id == workspace.id
    end

    test "with editor role (authorized scope) creates an account", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Editor Account", account_type: "credit_card"}

      assert {:ok, %Account{} = account} = CreateAccount.call(scope, workspace, attrs)
      assert account.name == "Editor Account"
      assert account.account_type == "credit_card"
      assert account.workspace_id == workspace.id
    end

    test "with commenter role (unauthorized scope) returns error", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Commenter Account", account_type: "checking"}

      assert {:error, :unauthorized} = CreateAccount.call(scope, workspace, attrs)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Unauthorized Account", account_type: "checking"}

      assert {:error, :unauthorized} = CreateAccount.call(scope, workspace, attrs)
    end

    test "invokes BroadcastWorkspace when account is created successfully", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      expect(BroadcastWorkspace, :call, fn broadcast_workspace, {:account_created, broadcast_account} ->
        assert broadcast_workspace == workspace
        assert broadcast_account.name == "Broadcast Test Account"
        :ok
      end)

      attrs = %{name: "Broadcast Test Account", account_type: "checking"}

      assert {:ok, %Account{}} = CreateAccount.call(scope, workspace, attrs)

      verify!()
    end

    test "assigns position 'm' for first account in a workspace", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "First Account", account_type: "checking"}

      assert {:ok, %Account{} = account} = CreateAccount.call(scope, workspace, attrs)
      assert account.position == "m"
    end

    test "assigns position before existing accounts", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      # Create first account
      AccountingFactory.insert(:account, workspace: workspace, position: "m")

      attrs = %{name: "Second Account", account_type: "savings"}

      assert {:ok, %Account{} = account} = CreateAccount.call(scope, workspace, attrs)
      assert account.position < "m"
      assert account.position == "g"
    end

    test "handles multiple accounts being added at the top", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      # Create initial accounts
      AccountingFactory.insert(:account, workspace: workspace, position: "g")
      AccountingFactory.insert(:account, workspace: workspace, position: "m")
      AccountingFactory.insert(:account, workspace: workspace, position: "t")

      attrs = %{name: "New Top Account", account_type: "cash"}

      assert {:ok, %Account{} = account} = CreateAccount.call(scope, workspace, attrs)
      assert account.position < "g"
      assert account.position == "d"
    end

    test "returns error when first account is already at 'a'", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      # Create an account at the boundary
      AccountingFactory.insert(:account, workspace: workspace, position: "a")

      attrs = %{name: "Cannot Place At Top", account_type: "checking"}

      assert {:error, :cannot_place_at_top} = CreateAccount.call(scope, workspace, attrs)
    end
  end
end
