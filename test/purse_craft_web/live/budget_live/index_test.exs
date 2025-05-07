defmodule PurseCraftWeb.BudgetLive.IndexTest do
  use PurseCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  describe "Budget page" do
    test "renders budget page elements", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/budget")

      assert html =~ "Budget"
      assert html =~ "Ready to Assign"
      assert html =~ "Assigned this Month"
      assert html =~ "Activity this Month"
      assert html =~ "Immediate Obligations"
      assert html =~ "True Expenses"
      assert html =~ "Quality of Life"
    end

    test "has functioning sidebar links", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/budget")

      # Check sidebar links are present
      assert has_element?(view, "a", "Budget")
      assert has_element?(view, "a", "Reports")
      assert has_element?(view, "a", "All Accounts")

      # The Budget link should be highlighted as active
      budget_link = element(view, "a", "Budget")
      assert render(budget_link) =~ "bg-primary"
    end

    test "renders user email in sidebar", %{conn: conn, user: user} do
      {:ok, _view, html} = live(conn, ~p"/budget")

      assert html =~ user.email
    end

    test "shows budget categories", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/budget")

      assert has_element?(view, "div", "Rent/Mortgage")
      assert has_element?(view, "div", "Electric")
      assert has_element?(view, "div", "Water")
      assert has_element?(view, "div", "Internet")
      assert has_element?(view, "div", "Groceries")

      # Test the category row's available class assignment
      # Verify the HTML contains the Internet category with zero available balance
      # This tests the case when available_float == 0
      html = render(view)
      assert html =~ "Internet"
      assert html =~ "$0.00"
      # Confirm the zero balance styling (should have no specific class)
      assert html =~
               ~s(Internet</span><div class="flex gap-8 text-sm"><span class="w-24 text-right">$75.00</span><span class="w-24 text-right">$-75.00</span><span class="w-24 text-right font-medium ">$0.00</span>)
    end

    test "shows action buttons", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/budget")

      assert has_element?(view, "button", "Add Category")
      assert has_element?(view, "button", "Auto-Assign")
    end

    test "shows all balance styling variants", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/budget")

      html = render(view)

      # Test for positive balance (text-success class)
      assert html =~ "Rent/Mortgage"
      assert html =~ "w-24 text-right font-medium text-success"

      # Test for zero balance (no additional class)
      assert html =~ "Internet"
      assert html =~ "$0.00"
      assert html =~ "w-24 text-right font-medium \">$0.00"

      # Test for negative balance (text-error class)
      assert html =~ "Overspent"
      assert html =~ "$-25.00"
      assert html =~ "w-24 text-right font-medium text-error"
    end
  end
end
