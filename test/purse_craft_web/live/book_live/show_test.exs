defmodule PurseCraftWeb.BookLive.ShowTest do
  use PurseCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias PurseCraft.BudgetingFactory

  setup :register_and_log_in_user

  describe "Display Book" do
    test "with associated book (authorized scope) displays book", %{conn: conn, user: user} do
      book = BudgetingFactory.insert(:book, name: "My Awesome Budget")
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)

      {:ok, _show_live, html} = live(conn, ~p"/books/#{book.external_id}")

      assert html =~ "Show Book"
      assert html =~ "My Awesome Budget"
    end
  end

  describe "Update Book" do
    test "with associated book, owner role, and valid data updates book and returns to show", %{conn: conn, user: user} do
      book = BudgetingFactory.insert(:book, name: "My Awesome Budget")
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      attrs = %{
        name: "My Spectacular Budget"
      }

      {:ok, show_live, _html} = live(conn, ~p"/books/#{book.external_id}")

      assert {:ok, form_live, _html} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/books/#{book.external_id}/edit?return_to=show")

      assert render(form_live) =~ "Edit Book"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#book-form", book: attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/books/#{book.external_id}")

      html = render(show_live)
      assert html =~ "Book updated successfully"
      assert html =~ "My Spectacular Budget"
      refute html =~ "My Awesome Budget"
    end

    test "with associated book, owner role, and blank name returns error", %{conn: conn, user: user} do
      book = BudgetingFactory.insert(:book, name: "My Awesome Budget")
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      attrs = %{
        name: ""
      }

      {:ok, show_live, _html} = live(conn, ~p"/books/#{book.external_id}")

      assert {:ok, form_live, _html} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/books/#{book.external_id}/edit?return_to=show")

      assert render(form_live) =~ "Edit Book"

      assert form_live
             |> form("#book-form", book: attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert form_live
             |> form("#book-form", book: attrs)
             |> render_submit() =~ "can&#39;t be blank"
    end
  end
end
