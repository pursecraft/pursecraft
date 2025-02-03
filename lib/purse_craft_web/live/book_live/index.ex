defmodule PurseCraftWeb.BookLive.Index do
  use PurseCraftWeb, :live_view

  alias PurseCraft.Budgeting
  alias PurseCraft.Budgeting.Schemas.Book

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :books, Budgeting.list_books())}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Book")
    |> assign(:book, Budgeting.get_book(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Book")
    |> assign(:book, %Book{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Books")
    |> assign(:book, nil)
  end

  @impl Phoenix.LiveView
  def handle_info({PurseCraftWeb.BookLive.FormComponent, {:saved, book}}, socket) do
    {:noreply, stream_insert(socket, :books, book)}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    case Budgeting.fetch_book(id) do
      {:ok, book} ->
        {:ok, _} = Budgeting.delete_book(book)
        {:noreply, stream_delete(socket, :books, book)}

      _any ->
        {:noreply, put_flash(socket, :error, "Book not found.")}
    end
  end
end
