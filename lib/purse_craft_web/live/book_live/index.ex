defmodule PurseCraftWeb.BookLive.Index do
  use PurseCraftWeb, :live_view

  alias PurseCraft.Budgeting

  @impl true
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
        row_click={fn {_id, book} -> JS.navigate(~p"/books/#{book}") end}
      >
        <:col :let={{_id, book}} label="Name">{book.name}</:col>
        <:action :let={{_id, book}}>
          <div class="sr-only">
            <.link navigate={~p"/books/#{book}"}>Show</.link>
          </div>
          <.link navigate={~p"/books/#{book}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, book}}>
          <.link
            phx-click={JS.push("delete", value: %{id: book.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    Budgeting.subscribe_books(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, "Listing Books")
     |> stream(:books, Budgeting.list_books(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    book = Budgeting.get_book!(socket.assigns.current_scope, id)
    {:ok, _} = Budgeting.delete_book(socket.assigns.current_scope, book)

    {:noreply, stream_delete(socket, :books, book)}
  end

  @impl true
  def handle_info({type, %PurseCraft.Budgeting.Book{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :books, Budgeting.list_books(socket.assigns.current_scope), reset: true)}
  end
end
