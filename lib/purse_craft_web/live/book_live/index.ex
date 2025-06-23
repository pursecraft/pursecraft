defmodule PurseCraftWeb.BookLive.Index do
  @moduledoc false
  use PurseCraftWeb, :live_view

  alias PurseCraft.Budgeting
  alias PurseCraft.Core.Schemas.Book
  alias PurseCraft.PubSub
  alias PurseCraftWeb.CoreComponents

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <CoreComponents.header>
        Listing Books
        <:actions>
          <CoreComponents.button variant="primary" navigate={~p"/books/new"}>
            <CoreComponents.icon name="hero-plus" /> New Book
          </CoreComponents.button>
        </:actions>
      </CoreComponents.header>

      <CoreComponents.table
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
          <.link navigate={~p"/books/#{book.external_id}/budget"}>
            Go to Budget View
          </.link>
          <.link navigate={~p"/books/#{book.external_id}/edit"}>Edit</.link>
        </:action>
        <:action :let={{_id, book}}>
          <.link
            phx-click={
              JS.push("delete", value: %{external_id: book.external_id})
              |> CoreComponents.hide("#books-#{book.external_id}")
            }
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </CoreComponents.table>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    PubSub.subscribe_user_books(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, "Listing Books")
     |> stream(:books, Budgeting.list_books(socket.assigns.current_scope))}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"external_id" => external_id}, socket) do
    case Budgeting.fetch_book_by_external_id(socket.assigns.current_scope, external_id) do
      {:ok, book} ->
        case Budgeting.delete_book(socket.assigns.current_scope, book) do
          {:ok, _book} ->
            {:noreply, stream_delete_by_dom_id(socket, :books, "books-#{book.external_id}")}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Failed to delete book")}
        end

      # coveralls-ignore-start
      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Book not found")}

      # coveralls-ignore-stop

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You don't have access to this book")}
    end
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
