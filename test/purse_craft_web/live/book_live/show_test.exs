defmodule PurseCraftWeb.BookLive.ShowTest do
  use PurseCraftWeb.ConnCase, async: true

  import Mimic
  import Phoenix.LiveViewTest

  alias PurseCraft.Budgeting
  alias PurseCraft.CoreFactory
  alias PurseCraft.Repo

  setup :register_and_log_in_user

  describe "Display Book" do
    test "with associated book (authorized scope) displays book", %{conn: conn, user: user} do
      book = CoreFactory.insert(:book, name: "My Awesome Budget")
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)

      {:ok, _show_live, html} = live(conn, ~p"/books/#{book.external_id}")

      assert html =~ "Show Book"
      assert html =~ "My Awesome Budget"
    end

    test "redirects to books page when book doesn't exist", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()

      assert {:error, {:live_redirect, %{to: "/books", flash: %{"error" => "You don't have access to this book"}}}} =
               live(conn, ~p"/books/#{non_existent_id}")
    end

    test "redirects to books page with not_found message when book doesn't exist with bypassed authorization", %{
      conn: conn
    } do
      non_existent_id = Ecto.UUID.generate()

      stub(PurseCraft.Budgeting.Policy, :authorize, fn _action, _scope, _book ->
        :ok
      end)

      assert {:error, {:live_redirect, %{to: "/books", flash: %{"error" => "Book not found"}}}} =
               live(conn, ~p"/books/#{non_existent_id}")
    end

    test "redirects to books page when unauthorized", %{conn: conn} do
      book = CoreFactory.insert(:book, name: "Someone Else's Budget")

      assert {:error, {:live_redirect, %{to: "/books", flash: %{"error" => "You don't have access to this book"}}}} =
               live(conn, ~p"/books/#{book.external_id}")
    end
  end

  describe "Update Book" do
    test "with associated book, owner role, and valid data updates book and returns to show", %{conn: conn, user: user} do
      book = CoreFactory.insert(:book, name: "My Awesome Budget")
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

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
      book = CoreFactory.insert(:book, name: "My Awesome Budget")
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

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

  describe "PubSub Book Update" do
    test "updates to the latest value of the book", %{conn: conn, user: user} do
      book = CoreFactory.insert(:book, name: "My Awesome Budget")
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      {:ok, show_live, html} = live(conn, ~p"/books/#{book.external_id}")

      assert html =~ "Show Book"
      assert html =~ "My Awesome Budget"

      {:ok, updated_book} =
        book
        |> Ecto.Changeset.change(name: "Updated via PubSub")
        |> Repo.update()

      Budgeting.broadcast_book(book, {:updated, updated_book})

      updated_html = render(show_live)
      assert updated_html =~ "Updated via PubSub"
      refute updated_html =~ "My Awesome Budget"
    end
  end

  describe "PubSub Book Delete" do
    test "deletions redirect current viewing users to /books", %{conn: conn, user: user} do
      book = CoreFactory.insert(:book, name: "My Awesome Budget")
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      {:ok, show_live, _html} = live(conn, ~p"/books/#{book.external_id}")

      Budgeting.broadcast_book(book, {:deleted, book})

      flash = assert_redirect(show_live, ~p"/books")
      assert flash["error"] == "The current book was deleted."
    end
  end

  describe "Book retrieval errors" do
    test "handles book update with fetch error", %{conn: conn, user: user} do
      book = CoreFactory.insert(:book, name: "My Awesome Budget")
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      {:ok, show_live, _html} = live(conn, ~p"/books/#{book.external_id}")

      stub(Budgeting, :fetch_book_by_external_id, fn _scope, external_id, _opts ->
        if external_id == book.external_id do
          {:error, :not_found}
        else
          {:error, :unauthorized}
        end
      end)

      rendered = render(show_live)
      assert rendered =~ "My Awesome Budget"

      Budgeting.broadcast_book(book, {:updated, book})

      assert render(show_live) =~ "My Awesome Budget"
    end

    test "handles book update with non-matching book data", %{conn: conn, user: user} do
      book = CoreFactory.insert(:book, name: "My Awesome Budget")
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      {:ok, show_live, _html} = live(conn, ~p"/books/#{book.external_id}")

      different_book = CoreFactory.insert(:book, name: "Different Book")

      Budgeting.broadcast_book(different_book, {:updated, different_book})

      assert render(show_live) =~ "My Awesome Budget"
      refute render(show_live) =~ "Different Book"
    end
  end
end
