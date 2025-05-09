defmodule PurseCraftWeb.BookLive.FormTest do
  use PurseCraftWeb.ConnCase, async: true

  import Mimic
  import Phoenix.LiveViewTest

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.BudgetingFactory

  setup :register_and_log_in_user

  describe "Edit Book Form" do
    test "creating new book shows form", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/books/new")

      assert html =~ "New Book"
      assert has_element?(view, "form#book-form")
    end

    test "handles not_found error in apply_action", %{conn: conn} do
      book_id = Ecto.UUID.generate()

      stub(Policy, :authorize, fn _action, _scope, _book ->
        :ok
      end)

      assert {:error, {:live_redirect, %{to: "/books", flash: %{"error" => "Book not found"}}}} =
               live(conn, ~p"/books/#{book_id}/edit")
    end

    test "redirects when book doesn't exist with not_found error", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()

      stub(Policy, :authorize, fn _action, _scope, _book ->
        :ok
      end)

      assert {:error, {:live_redirect, %{to: "/books", flash: %{"error" => "Book not found"}}}} =
               live(conn, ~p"/books/#{non_existent_id}/edit")
    end

    test "redirects when book doesn't exist", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()

      assert {:error, {:live_redirect, %{to: "/books", flash: %{"error" => "You don't have access to this book"}}}} =
               live(conn, ~p"/books/#{non_existent_id}/edit")
    end

    test "redirects when unauthorized", %{conn: conn} do
      book = BudgetingFactory.insert(:book, name: "Someone Else's Budget")

      assert {:error, {:live_redirect, %{to: "/books", flash: %{"error" => "You don't have access to this book"}}}} =
               live(conn, ~p"/books/#{book.external_id}/edit")
    end
  end
end
