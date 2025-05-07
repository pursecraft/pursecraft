defmodule PurseCraftWeb.Components.UI.Budgeting.SidebarTest do
  use PurseCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias PurseCraftWeb.Components.UI.Budgeting.Sidebar

  describe "sidebar/1" do
    test "renders the sidebar with navigation links" do
      user = PurseCraft.IdentityFactory.build(:user, email: "test@example.com")
      scope = PurseCraft.IdentityFactory.build(:scope, user: user)

      result =
        render_component(&Sidebar.sidebar/1, %{
          current_path: "/budget",
          current_scope: scope
        })

      # Check for PurseCraft logo and name
      assert result =~ "PurseCraft Logo"
      assert result =~ "PurseCraft"

      # Check for navigation links
      assert result =~ "Budget"
      assert result =~ "Reports"
      assert result =~ "All Accounts"

      # Check for user info
      assert result =~ "test@example.com"
      assert result =~ "Settings"

      # Check for month selector
      assert result =~ "May 2025"
    end

    test "highlights the active route" do
      user = PurseCraft.IdentityFactory.build(:user, email: "test@example.com")
      scope = PurseCraft.IdentityFactory.build(:scope, user: user)

      # Test with budget active
      budget_result =
        render_component(&Sidebar.sidebar/1, %{
          current_path: "/budget",
          current_scope: scope
        })

      assert budget_result =~ ~r/<a[^>]*href="\/budget"[^>]*class="[^"]*bg-primary/
      assert budget_result =~ ~r/<a[^>]*href="\/reports"[^>]*class="[^"]*text-base-content/

      # Test with reports active
      reports_result =
        render_component(&Sidebar.sidebar/1, %{
          current_path: "/reports",
          current_scope: scope
        })

      assert reports_result =~ ~r/<a[^>]*href="\/budget"[^>]*class="[^"]*text-base-content/
      assert reports_result =~ ~r/<a[^>]*href="\/reports"[^>]*class="[^"]*bg-primary/

      # Test with accounts active
      accounts_result =
        render_component(&Sidebar.sidebar/1, %{
          current_path: "/accounts",
          current_scope: scope
        })

      assert accounts_result =~ ~r/<a[^>]*href="\/accounts"[^>]*class="[^"]*bg-primary/
    end

    test "renders book selection dropdown" do
      user = PurseCraft.IdentityFactory.build(:user, email: "test@example.com")
      scope = PurseCraft.IdentityFactory.build(:scope, user: user)

      result =
        render_component(&Sidebar.sidebar/1, %{
          current_path: "/budget",
          current_scope: scope
        })

      assert result =~ "<select"
      assert result =~ "My Budget"
      assert result =~ "Family Budget"
      assert result =~ "+ Create New Budget"
    end

    test "renders logout form" do
      user = PurseCraft.IdentityFactory.build(:user, email: "test@example.com")
      scope = PurseCraft.IdentityFactory.build(:scope, user: user)

      result =
        render_component(&Sidebar.sidebar/1, %{
          current_path: "/budget",
          current_scope: scope
        })

      assert result =~ ~r/<form[^>]*action="\/users\/log-out"/
      assert result =~ "Log out"
    end

    test "renders user initial in avatar" do
      user = PurseCraft.IdentityFactory.build(:user, email: "test@example.com")
      scope = PurseCraft.IdentityFactory.build(:scope, user: user)

      result =
        render_component(&Sidebar.sidebar/1, %{
          current_path: "/budget",
          current_scope: scope
        })

      # The avatar should contain the uppercase first letter of the email
      assert result =~ "<span>T</span>"
    end
  end
end
