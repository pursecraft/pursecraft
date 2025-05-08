defmodule PurseCraftWeb.Components.UI.Budgeting.MobileSidebarTest do
  use PurseCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  setup %{user: user} do
    book = PurseCraft.BudgetingFactory.insert(:book, name: "Test Budget Book")
    PurseCraft.BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
    %{book: book}
  end

  describe "Mobile sidebar" do
    test "toggles sidebar visibility on button click", %{conn: conn, book: book} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      # Check that sidebar is initially hidden on mobile
      html = render(view)
      assert html =~ "id=\"sidebar-container\""
      assert html =~ "-translate-x-full lg:translate-x-0"

      # Click the menu button to show sidebar
      visible_html =
        view
        |> element("button[aria-label='Toggle menu']")
        |> render_click()

      # Now the sidebar should be visible
      assert visible_html =~ "translate-x-0"
      refute visible_html =~ "-translate-x-full lg:translate-x-0"

      # Click the overlay to hide sidebar
      hidden_html =
        view
        |> element("#mobile-sidebar-overlay")
        |> render_click()

      # The sidebar should be hidden again
      assert hidden_html =~ "-translate-x-full lg:translate-x-0"

      refute hidden_html =~
               ~s(id="sidebar-container" class="w-[280px] flex-shrink-0 border-r border-base-300 bg-base-200 overflow-y-auto flex flex-col fixed lg:static h-full z-50 transition-transform duration-300 ease-in-out shadow-lg translate-x-0")
    end
  end
end
