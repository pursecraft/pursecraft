defmodule PurseCraftWeb.BookLive.IndexTest do
  use PurseCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias PurseCraft.BudgetingFactory

  setup :register_and_log_in_user

  describe "List Books" do
    test "returns all scoped books", %{conn: conn, user: user} do
      book = BudgetingFactory.insert(:book, name: "Book 1")
      BudgetingFactory.insert(:book, name: "Book 2")
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id)

      {:ok, _index_live, html} = live(conn, ~p"/books")

      assert html =~ "Listing Books"
      assert html =~ "Book 1"
      refute html =~ "Book 2"
    end
  end

  describe "Create Book" do
    test "with valid data creates new book", %{conn: conn} do
      attrs = %{
        name: "Some Book"
      }

      {:ok, index_live, _html} = live(conn, ~p"/books")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Book")
               |> render_click()
               |> follow_redirect(conn, ~p"/books/new")

      assert render(form_live) =~ "New Book"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#book-form", book: attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/books")

      html = render(index_live)
      assert html =~ "Book created successfully"
      assert html =~ "Some Book"
    end

    test "with blank name returns error", %{conn: conn} do
      attrs = %{
        name: ""
      }

      {:ok, index_live, _html} = live(conn, ~p"/books")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Book")
               |> render_click()
               |> follow_redirect(conn, ~p"/books/new")

      assert form_live
             |> form("#book-form", book: attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert form_live
             |> form("#book-form", book: attrs)
             |> render_change() =~ "can&#39;t be blank"
    end
  end

  describe "Update Book" do
    test "with owner role and valid data updates book", %{conn: conn, user: user} do
      book = BudgetingFactory.insert(:book, name: "Book 1")
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      attrs = %{
        name: "Updated Book"
      }

      {:ok, index_live, _html} = live(conn, ~p"/books")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#books-#{book.external_id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/books/#{book.external_id}/edit")

      assert render(form_live) =~ "Edit Book"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#book-form", book: attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/books")

      html = render(index_live)
      assert html =~ "Book updated successfully"
      assert html =~ "Updated Book"
      refute html =~ "Book 1"
    end

    test "with blank name returns error", %{conn: conn, user: user} do
      book = BudgetingFactory.insert(:book, name: "Book 1")
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      attrs = %{
        name: ""
      }

      {:ok, index_live, _html} = live(conn, ~p"/books")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#books-#{book.external_id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/books/#{book.external_id}/edit")

      assert render(form_live) =~ "Edit Book"

      assert form_live
             |> form("#book-form", book: attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert form_live
             |> form("#book-form", book: attrs)
             |> render_submit() =~ "can&#39;t be blank"
    end
  end

  describe "Delete Book" do
    test "with owner role and associated book deletes book in listing", %{conn: conn, user: user} do
      book = BudgetingFactory.insert(:book)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      {:ok, index_live, _html} = live(conn, ~p"/books")

      assert index_live |> element("#books-#{book.external_id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#books-#{book.external_id}")
    end
  end
end
