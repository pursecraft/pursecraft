defmodule PurseCraftWeb.BookLiveTest do
  use PurseCraftWeb.ConnCase

  import Phoenix.LiveViewTest
  import PurseCraft.BudgetingFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  setup :register_and_log_in_user

  defp create_book(%{scope: scope}) do
    book = book_fixture(scope)

    %{book: book}
  end

  describe "Index" do
    setup [:create_book]

    test "lists all books", %{conn: conn, book: book} do
      {:ok, _index_live, html} = live(conn, ~p"/books")

      assert html =~ "Listing Books"
      assert html =~ book.name
    end

    test "saves new book", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/books")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Book")
               |> render_click()
               |> follow_redirect(conn, ~p"/books/new")

      assert render(form_live) =~ "New Book"

      assert form_live
             |> form("#book-form", book: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#book-form", book: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/books")

      html = render(index_live)
      assert html =~ "Book created successfully"
      assert html =~ "some name"
    end

    test "updates book in listing", %{conn: conn, book: book} do
      {:ok, index_live, _html} = live(conn, ~p"/books")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#books-#{book.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/books/#{book}/edit")

      assert render(form_live) =~ "Edit Book"

      assert form_live
             |> form("#book-form", book: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#book-form", book: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/books")

      html = render(index_live)
      assert html =~ "Book updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes book in listing", %{conn: conn, book: book} do
      {:ok, index_live, _html} = live(conn, ~p"/books")

      assert index_live |> element("#books-#{book.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#books-#{book.id}")
    end
  end

  describe "Show" do
    setup [:create_book]

    test "displays book", %{conn: conn, book: book} do
      {:ok, _show_live, html} = live(conn, ~p"/books/#{book}")

      assert html =~ "Show Book"
      assert html =~ book.name
    end

    test "updates book and returns to show", %{conn: conn, book: book} do
      {:ok, show_live, _html} = live(conn, ~p"/books/#{book}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/books/#{book}/edit?return_to=show")

      assert render(form_live) =~ "Edit Book"

      assert form_live
             |> form("#book-form", book: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#book-form", book: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/books/#{book}")

      html = render(show_live)
      assert html =~ "Book updated successfully"
      assert html =~ "some updated name"
    end
  end
end
