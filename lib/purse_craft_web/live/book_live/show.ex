defmodule PurseCraftWeb.BookLive.Show do
  use PurseCraftWeb, :live_view

  alias PurseCraft.Budgeting
  alias PurseCraft.Budgeting.Schemas.Book

  @impl true
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
          <.button variant="primary" navigate={~p"/books/#{@book}/edit?return_to=show"}>
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

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    Budgeting.subscribe_books(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, "Show Book")
     |> assign(:book, Budgeting.get_book!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %Book{id: id} = book},
        %{assigns: %{book: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :book, book)}
  end

  def handle_info(
        {:deleted, %Book{id: id}},
        %{assigns: %{book: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current book was deleted.")
     |> push_navigate(to: ~p"/books")}
  end
end
