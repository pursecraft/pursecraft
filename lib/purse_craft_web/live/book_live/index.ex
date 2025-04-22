defmodule PurseCraftWeb.BookLive.Index do
  @moduledoc false
  use PurseCraftWeb, :live_view

  alias PurseCraft.Budgeting
  alias PurseCraft.Budgeting.Schemas.Book

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Books
        <:actions>
          <.button variant="primary" navigate={~p"/books/new"}>
            <.icon name="hero-plus" /> New Book
          </.button>
        </:actions>
      </.header>

      <.table
        id="books"
        rows={@streams.books}
        row_id={fn {_id, book} -> "books-#{book.external_id}" end}
        row_click={fn {_id, book} -> JS.navigate(~p"/books/#{book.external_id}") end}
      >
        <:col :let={{_id, book}} label="Name">{book.name}</:col>
        <:action :let={{_id, book}}>
          <div class="sr-only">
            <.link navigate={~p"/books/#{book.external_id}"}>Show</.link>
          </div>
          <.link navigate={~p"/books/#{book.external_id}/edit"}>Edit</.link>
        </:action>
        <:action :let={{_id, book}}>
          <.link
            phx-click={
              JS.push("delete", value: %{external_id: book.external_id})
              |> hide("#books-#{book.external_id}")
            }
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    Budgeting.subscribe_user_books(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, "Listing Books")
     |> stream(:books, Budgeting.list_books(socket.assigns.current_scope))}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"external_id" => external_id}, socket) do
    book = Budgeting.get_book_by_external_id!(socket.assigns.current_scope, external_id)
    {:ok, _book} = Budgeting.delete_book(socket.assigns.current_scope, book)

    {:noreply, stream_delete_by_dom_id(socket, :books, "books-#{book.external_id}")}
  end

  @impl Phoenix.LiveView
  def handle_info({:deleted, %Book{} = book}, socket) do
    {:noreply, stream_delete_by_dom_id(socket, :books, "books-#{book.external_id}")}
  end

  @impl Phoenix.LiveView
  def handle_info({type, %Book{}}, socket) when type in [:created, :updated] do
    books = Budgeting.list_books(socket.assigns.current_scope)
    {:noreply, stream(socket, :books, books, reset: true)}
  end
end
