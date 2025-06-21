defmodule PurseCraftWeb.BookLive.IndexTest do
  use PurseCraftWeb.ConnCase, async: true

  import Mimic
  import Phoenix.LiveViewTest

  alias PurseCraft.Budgeting
  alias PurseCraft.IdentityFactory
  alias PurseCraft.Repo

  setup :register_and_log_in_user

  describe "List Books" do
    test "returns all scoped books", %{conn: conn, user: user} do
      book = IdentityFactory.insert(:book, name: "Book 1")
      IdentityFactory.insert(:book, name: "Book 2")
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id)

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

      assert {:ok, form_live, _html} =
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

      assert {:ok, form_live, _html} =
               index_live
               |> element("a", "New Book")
               |> render_click()
               |> follow_redirect(conn, ~p"/books/new")

      assert form_live
             |> form("#book-form", book: attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert form_live
             |> form("#book-form", book: attrs)
             |> render_submit() =~ "can&#39;t be blank"
    end
  end

  describe "Update Book" do
    test "with owner role and valid data updates book", %{conn: conn, user: user} do
      book = IdentityFactory.insert(:book, name: "Book 1")
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

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
      book = IdentityFactory.insert(:book, name: "Book 1")
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

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
    test "deleting non-existent book returns flash error", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/books")

      stub(Budgeting, :fetch_book_by_external_id, fn _scope, _id, _opts ->
        {:error, :not_found}
      end)

      result = render_hook(view, "delete", %{"external_id" => Ecto.UUID.generate()})

      assert has_element?(view, "#flash-error")

      assert result =~ "flash-error"
    end

    test "with unauthorized scope returns flash error", %{conn: conn, user: user} do
      book = IdentityFactory.insert(:book)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)

      {:ok, view, _html} = live(conn, ~p"/books")

      render_hook(view, "delete", %{"external_id" => book.external_id})

      assert has_element?(view, "#flash-error")
      assert render(view) =~ "Failed to delete book"
    end

    test "handles error when book deletion fails", %{conn: conn, user: user} do
      book = IdentityFactory.insert(:book)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      {:ok, view, _html} = live(conn, ~p"/books")

      stub(Budgeting, :delete_book, fn _scope, _book ->
        {:error, :some_error}
      end)

      render_hook(view, "delete", %{"external_id" => book.external_id})

      assert has_element?(view, "#flash-error")
      assert render(view) =~ "Failed to delete book"
    end

    test "with owner role and associated book deletes book in listing", %{conn: conn, user: user} do
      book = IdentityFactory.insert(:book)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      {:ok, index_live, _html} = live(conn, ~p"/books")

      assert index_live
             |> element("#books-#{book.external_id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#books-#{book.external_id}")
    end
  end

  describe "PubSub Book Update" do
    test "updates to the latest value of the book", %{conn: conn, scope: scope, user: user} do
      book = IdentityFactory.insert(:book, name: "My Awesome Budget")
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      {:ok, index_live, html} = live(conn, ~p"/books")

      assert html =~ "Listing Books"
      assert html =~ "My Awesome Budget"

      {:ok, updated_book} =
        book
        |> Ecto.Changeset.change(name: "Updated via PubSub")
        |> Repo.update()

      Budgeting.broadcast_user_book(scope, {:updated, updated_book})

      updated_html = render(index_live)
      assert updated_html =~ "Updated via PubSub"
      refute updated_html =~ "My Awesome Budget"
    end
  end

  describe "PubSub Book Delete" do
    test "deletions remove book from listing", %{conn: conn, scope: scope, user: user} do
      book = IdentityFactory.insert(:book, name: "My Awesome Budget")
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      {:ok, index_live, html} = live(conn, ~p"/books")

      assert html =~ "My Awesome Budget"

      {:ok, deleted_book} = Repo.delete(book)
      Budgeting.broadcast_user_book(scope, {:deleted, deleted_book})

      updated_html = render(index_live)
      refute updated_html =~ "My Awesome Budget"
    end
  end
end
