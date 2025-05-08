defmodule PurseCraftWeb.BookLive.Show do
  @moduledoc false
  use PurseCraftWeb, :live_view

  alias PurseCraft.Budgeting
  alias PurseCraft.Budgeting.Schemas.Book

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Book {@book.id}
        <:subtitle>This is a book record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/books"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/books/#{@book.external_id}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit book
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@book.name}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"external_id" => external_id}, _session, socket) do
    book = Budgeting.get_book_by_external_id!(socket.assigns.current_scope, external_id)
    Budgeting.subscribe_book(book)

    {:ok,
     socket
     |> assign(:page_title, "Show Book")
     |> assign(:book, book)}
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:updated, %Book{external_id: external_id} = book},
        %{assigns: %{book: %{external_id: external_id}}} = socket
      ) do
    {:noreply, assign(socket, :book, book)}
  end

  def handle_info({:deleted, %Book{external_id: external_id}}, %{assigns: %{book: %{external_id: external_id}}} = socket) do
    {:noreply,
     socket
     |> put_flash(:error, "The current book was deleted.")
     |> push_navigate(to: ~p"/books")}
  end
end
