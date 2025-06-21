defmodule PurseCraftWeb.BookLive.Form do
  @moduledoc false
  use PurseCraftWeb, :live_view

  alias PurseCraft.Budgeting
  alias PurseCraft.Identity.Schemas.Book
  alias PurseCraftWeb.CoreComponents

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <CoreComponents.header>
        {@page_title}
        <:subtitle>Use this form to manage book records in your database.</:subtitle>
      </CoreComponents.header>

      <.form for={@form} id="book-form" phx-change="validate" phx-submit="save">
        <CoreComponents.input field={@form[:name]} type="text" label="Name" />
        <footer>
          <CoreComponents.button phx-disable-with="Saving..." variant="primary">
            Save Book
          </CoreComponents.button>
          <CoreComponents.button navigate={return_path(@current_scope, @return_to, @book)}>
            Cancel
          </CoreComponents.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_action), do: "index"

  defp apply_action(socket, :edit, %{"external_id" => external_id}) do
    case Budgeting.fetch_book_by_external_id(socket.assigns.current_scope, external_id) do
      {:ok, book} ->
        socket
        |> assign(:page_title, "Edit Book")
        |> assign(:book, book)
        |> assign(:form, to_form(Budgeting.change_book(book)))

      {:error, :not_found} ->
        socket
        |> put_flash(:error, "Book not found")
        |> push_navigate(to: ~p"/books")

      {:error, :unauthorized} ->
        socket
        |> put_flash(:error, "You don't have access to this book")
        |> push_navigate(to: ~p"/books")
    end
  end

  defp apply_action(socket, :new, _params) do
    book = %Book{}

    socket
    |> assign(:page_title, "New Book")
    |> assign(:book, book)
    |> assign(:form, to_form(Budgeting.change_book(book)))
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"book" => book_params}, socket) do
    changeset = Budgeting.change_book(socket.assigns.book, book_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"book" => book_params}, socket) do
    save_book(socket, socket.assigns.live_action, book_params)
  end

  defp save_book(socket, :edit, book_params) do
    case Budgeting.update_book(socket.assigns.current_scope, socket.assigns.book, book_params) do
      {:ok, book} ->
        {:noreply,
         socket
         |> put_flash(:info, "Book updated successfully")
         |> push_navigate(to: return_path(socket.assigns.current_scope, socket.assigns.return_to, book.external_id))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_book(socket, :new, book_params) do
    case Budgeting.create_book(socket.assigns.current_scope, book_params) do
      {:ok, book} ->
        {:noreply,
         socket
         |> put_flash(:info, "Book created successfully")
         |> push_navigate(to: return_path(socket.assigns.current_scope, socket.assigns.return_to, book))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _book), do: ~p"/books"
  defp return_path(_scope, "show", book), do: ~p"/books/#{book}"
end
