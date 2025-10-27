defmodule PurseCraft.AccountingTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Accounting
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

  setup do
    user = IdentityFactory.insert(:user)
    workspace = CoreFactory.insert(:workspace)
    CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
    scope = IdentityFactory.build(:scope, user: user)

    %{
      user: user,
      scope: scope,
      workspace: workspace
    }
  end

  describe "create_account/2 (with default attrs)" do
    test "creates an account with default empty attrs", %{scope: scope, workspace: workspace} do
      assert {:error, changeset} = Accounting.create_account(scope, workspace)
      assert %{name: ["can't be blank"], account_type: ["can't be blank"]} = errors_on(changeset)
    end
  end
end
