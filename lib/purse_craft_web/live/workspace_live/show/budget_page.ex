defmodule PurseCraftWeb.WorkspaceLive.Show.BudgetPage do
  @moduledoc false
  use PurseCraftWeb, :live_component

  alias PurseCraft.Budgeting
  alias PurseCraft.Budgeting.Commands.Categories.RepositionCategory
  alias PurseCraft.Budgeting.Commands.Envelopes.RepositionEnvelope
  alias PurseCraft.Budgeting.Repositories.CategoryRepository
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.PubSub
  alias PurseCraftWeb.Components.UI.Core.Button
  alias PurseCraftWeb.Components.UI.Core.Card
  alias PurseCraftWeb.Components.UI.Core.Form
  alias PurseCraftWeb.Components.UI.Core.Modal
  alias PurseCraftWeb.WorkspaceLive.Components.BudgetHeader
  alias PurseCraftWeb.WorkspaceLive.Components.CategorySection
  alias PurseCraftWeb.WorkspaceLive.Components.EnvelopeRow

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign(:category_form, to_form(Budgeting.change_category(%Category{})))
     |> assign(:envelope_form, to_form(Budgeting.change_envelope(%Envelope{})))
     |> assign(:category_modal_open, false)
     |> assign(:envelope_modal_open, false)
     |> assign(:delete_modal_open, false)
     |> assign(:editing_category, nil)
     |> assign(:editing_envelope, nil)
     |> assign(:category_to_delete, nil)
     |> assign(:envelope_to_delete, nil)
     |> assign(:selected_category_for_envelope, nil)
     |> assign(:envelope_modal_title, "Add New Envelope")
     |> assign(:envelope_modal_action, "save_envelope")
     |> assign(:envelope_modal_button, "Create")
     |> assign(:modal_title, "Add New Category")
     |> assign(:modal_action, "save_category")
     |> assign(:modal_button, "Create")
     |> stream_configure(:categories, dom_id: &"categories-#{&1.external_id}")}
  end

  @impl Phoenix.LiveComponent
  def update(%{action: :category_repositioned}, socket) do
    socket = handle_category_repositioned(socket)
    {:ok, socket}
  end

  def update(%{action: :category_created}, socket) do
    socket = reload_categories(socket)
    {:ok, socket}
  end

  def update(%{action: :category_updated}, socket) do
    socket = reload_categories(socket)
    {:ok, socket}
  end

  def update(%{action: :category_deleted}, socket) do
    socket = reload_categories(socket)
    {:ok, socket}
  end

  def update(%{action: :envelope_repositioned, data: data}, socket) do
    socket = handle_envelope_repositioned(socket, data)
    {:ok, socket}
  end

  def update(%{action: :envelope_created}, socket) do
    socket = reload_categories(socket)
    {:ok, socket}
  end

  def update(%{action: :envelope_updated}, socket) do
    socket = reload_categories(socket)
    {:ok, socket}
  end

  def update(%{action: :envelope_deleted}, socket) do
    socket = reload_categories(socket)
    {:ok, socket}
  end

  def update(%{action: :envelope_removed, data: data}, socket) do
    socket = handle_envelope_removed(socket, data)
    {:ok, socket}
  end

  def update(%{action: :reposition_envelope, params: params}, socket) do
    case RepositionEnvelope.call(
           socket.assigns.current_scope,
           params["envelope_id"],
           params["target_category_id"],
           params["prev_envelope_id"],
           params["next_envelope_id"]
         ) do
      {:ok, _updated_envelope} ->
        {:ok, socket}

      {:error, :unauthorized} ->
        send(self(), {:put_flash, :error, "You don't have permission to reposition envelopes"})
        {:ok, socket}

      {:error, :not_found} ->
        send(self(), {:put_flash, :error, "Envelope or category not found"})
        {:ok, socket}

      {:error, _reason} ->
        send(self(), {:put_flash, :error, "Failed to save envelope position. Please try again."})
        {:ok, socket}
    end
  end

  def update(%{action: :delete_category, params: params}, socket) do
    external_id = params["id"]

    case Budgeting.fetch_category_by_external_id(socket.assigns.current_scope, socket.assigns.workspace, external_id,
           preload: [:envelopes]
         ) do
      {:ok, category} ->
        handle_category_deletion(socket, category)

      {:error, :not_found} ->
        send(self(), {:put_flash, :error, "Category not found"})
        {:ok, socket}

      {:error, :unauthorized} ->
        send(self(), {:put_flash, :error, "You don't have permission to delete this category"})
        {:ok, socket}
    end
  end

  def update(%{action: :reposition_category, params: params}, socket) do
    case RepositionCategory.call(
           socket.assigns.current_scope,
           params["category_id"],
           params["prev_category_id"],
           params["next_category_id"]
         ) do
      {:ok, _updated_category} ->
        {:ok, socket}

      {:error, :unauthorized} ->
        send(self(), {:put_flash, :error, "You don't have permission to reposition categories"})
        {:ok, socket}

      {:error, :not_found} ->
        send(self(), {:put_flash, :error, "Category not found"})
        {:ok, socket}

      {:error, _reason} ->
        send(self(), {:put_flash, :error, "Failed to save category position. Please try again."})
        {:ok, socket}
    end
  end

  def update(%{action: :delete_envelope, params: params}, socket) do
    external_id = params["id"]

    case Budgeting.fetch_envelope_by_external_id(socket.assigns.current_scope, socket.assigns.workspace, external_id,
           preload: [category: [:envelopes]]
         ) do
      {:ok, envelope} ->
        case Budgeting.delete_envelope(socket.assigns.current_scope, socket.assigns.workspace, envelope) do
          {:ok, deleted_envelope} ->
            updated_envelopes = Enum.reject(envelope.category.envelopes, fn e -> e.id == deleted_envelope.id end)
            updated_category = %{envelope.category | envelopes: updated_envelopes}

            socket =
              socket
              |> stream_insert(:categories, updated_category)
              |> hide_delete_modal()

            send(self(), {:put_flash, :info, "Envelope deleted successfully"})
            {:ok, socket}

          {:error, :unauthorized} ->
            send(self(), {:put_flash, :error, "You don't have permission to delete this envelope"})
            {:ok, hide_delete_modal(socket)}

          {:error, _reason} ->
            send(self(), {:put_flash, :error, "Error deleting envelope"})
            {:ok, hide_delete_modal(socket)}
        end

      {:error, :not_found} ->
        send(self(), {:put_flash, :error, "Envelope not found"})
        {:ok, socket}

      {:error, :unauthorized} ->
        send(self(), {:put_flash, :error, "You don't have permission to delete this envelope"})
        {:ok, socket}
    end
  end

  def update(%{workspace: workspace, current_scope: current_scope} = assigns, socket) do
    case Budgeting.list_categories(current_scope, workspace, preload: [:envelopes]) do
      {:error, :unauthorized} ->
        send(self(), {:put_flash, :error, "You don't have access to this workspace's categories"})
        {:ok, socket}

      categories ->
        subscribe_to_categories(categories)

        socket =
          socket
          |> assign(assigns)
          |> stream(:categories, categories)

        {:ok, socket}
    end
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    assigns = assign_new(assigns, :workspace, fn -> nil end)

    ~H"""
    <div class="space-y-6 w-full max-w-7xl mx-auto">
      <div :if={@workspace}>
        <BudgetHeader.render
          workspace_name={@workspace.name}
          on_add_category="new_category"
          target={@myself}
        />

        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mt-6">
          <Card.summary_card title="Ready to Assign" amount="$1,250.00" variant="success" />
          <Card.summary_card title="Assigned this Month" amount="$3,750.00" />
          <Card.summary_card title="Activity this Month" amount="-$2,130.45" />
        </div>

        <div class="space-y-2">
          <div class="overflow-x-auto">
            <div class="min-w-[600px]">
              <div
                id="categories"
                phx-hook="CategoryDragDrop"
                phx-update="stream"
                class="space-y-4"
                data-item-id-attribute="categoryId"
                data-reposition-event="reposition_category"
                data-deletion-event="category_deleted"
                data-id-field="category_id"
                data-prev-id-field="prev_category_id"
                data-next-id-field="next_category_id"
                phx-target={@myself}
              >
                <CategorySection.render
                  :for={{dom_id, category} <- @streams.categories}
                  id={dom_id}
                  category={category}
                  target={@myself}
                >
                  <EnvelopeRow.render
                    :for={envelope <- category.envelopes}
                    id={envelope.external_id}
                    name={envelope.name}
                    assigned="100.00"
                    activity="0.00"
                    available="100.00"
                    target={@myself}
                  />
                </CategorySection.render>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Category Modal -->
        <Modal.form_modal
          :if={@category_modal_open}
          id="category-modal"
          show={@category_modal_open}
          title={@modal_title}
          on_close="cancel_category"
        >
          <.form
            for={@category_form}
            id="category-form"
            phx-submit={@modal_action}
            phx-target={@myself}
            phx-change="validate_category"
          >
            <Form.input field={@category_form[:name]} type="text" label="Category Name" required />
          </.form>

          <:actions>
            <Button.button variant="outline" phx-click="cancel_category_form" phx-target={@myself}>
              Cancel
            </Button.button>
            <Button.button variant="primary" type="submit" form="category-form" phx-target={@myself}>
              {@modal_button}
            </Button.button>
          </:actions>
        </Modal.form_modal>
        
    <!-- Envelope Modal -->
        <Modal.form_modal
          :if={@envelope_modal_open}
          id="envelope-modal"
          show={@envelope_modal_open}
          title={@envelope_modal_title}
          on_close="cancel_envelope"
        >
          <.form
            for={@envelope_form}
            id="envelope-form"
            phx-submit={@envelope_modal_action}
            phx-target={@myself}
            phx-change="validate_envelope"
          >
            <Form.input field={@envelope_form[:name]} type="text" label="Envelope Name" required />
          </.form>

          <:actions>
            <Button.button variant="outline" phx-click="cancel_envelope_form" phx-target={@myself}>
              Cancel
            </Button.button>
            <Button.button variant="primary" type="submit" form="envelope-form" phx-target={@myself}>
              {@envelope_modal_button}
            </Button.button>
          </:actions>
        </Modal.form_modal>
        
    <!-- Delete Confirmation Modal -->
        <Modal.confirmation_modal
          :if={@delete_modal_open}
          id="delete-modal"
          show={@delete_modal_open}
          title="Confirm Deletion"
          on_close="cancel_delete"
          on_confirm={if @category_to_delete, do: "delete_category", else: "delete_envelope"}
          confirm_value={
            (@category_to_delete && @category_to_delete.external_id) ||
              (@envelope_to_delete && @envelope_to_delete.external_id)
          }
          confirm_text="Delete"
        >
          <p class="text-base-content">
            Are you sure you want to delete this {if @category_to_delete,
              do: "category",
              else: "envelope"}? This action cannot be undone.
          </p>
        </Modal.confirmation_modal>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def handle_event("new_category", _params, socket) do
    {:noreply, show_category_modal(socket)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("cancel_category", _params, socket) do
    {:noreply, hide_category_modal(socket)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("cancel_category_form", _params, socket) do
    {:noreply, hide_category_modal(socket)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("edit_category", %{"id" => external_id}, socket) do
    socket.assigns.current_scope
    |> Budgeting.fetch_category_by_external_id(socket.assigns.workspace, external_id)
    |> case do
      {:ok, category} ->
        {:noreply, show_category_modal(socket, category)}

      {:error, :not_found} ->
        send(self(), {:put_flash, :error, "Category not found"})
        {:noreply, socket}

      {:error, :unauthorized} ->
        send(self(), {:put_flash, :error, "You don't have permission to edit this category"})
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate_category", %{"category" => category_params}, socket) do
    changeset = Budgeting.change_category(%Category{}, category_params)
    {:noreply, assign(socket, :category_form, to_form(changeset, action: :validate))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save_category", %{"category" => category_params}, socket) do
    category = socket.assigns.editing_category

    if category && category.id do
      handle_category_update(socket, category, category_params)
    else
      handle_category_create(socket, category_params)
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("delete_category_confirm", %{"id" => external_id}, socket) do
    socket.assigns.current_scope
    |> Budgeting.fetch_category_by_external_id(socket.assigns.workspace, external_id, preload: [:envelopes])
    |> case do
      {:ok, category} ->
        if Enum.empty?(category.envelopes) do
          {:noreply, show_delete_modal(socket, category, :category)}
        else
          send(self(), {:put_flash, :error, "Cannot delete a category with envelopes"})
          {:noreply, socket}
        end

      {:error, :not_found} ->
        send(self(), {:put_flash, :error, "Category not found"})
        {:noreply, socket}

      {:error, :unauthorized} ->
        send(self(), {:put_flash, :error, "You don't have permission to delete this category"})
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("cancel_delete", _params, socket) do
    {:noreply, hide_delete_modal(socket)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("delete_category", %{"id" => _external_id}, socket) do
    category = socket.assigns.category_to_delete

    socket.assigns.current_scope
    |> Budgeting.delete_category(socket.assigns.workspace, category)
    |> case do
      {:ok, deleted_category} ->
        socket =
          socket
          |> stream_delete(:categories, deleted_category)
          |> hide_delete_modal()

        send(self(), {:put_flash, :info, "Category deleted successfully"})
        {:noreply, socket}

      {:error, :unauthorized} ->
        send(self(), {:put_flash, :error, "You don't have permission to delete this category"})
        {:noreply, hide_delete_modal(socket)}

      {:error, _reason} ->
        send(self(), {:put_flash, :error, "Error deleting category"})
        {:noreply, hide_delete_modal(socket)}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("new_envelope", %{"id" => external_id}, socket) do
    socket.assigns.current_scope
    |> Budgeting.fetch_category_by_external_id(socket.assigns.workspace, external_id, preload: [:envelopes])
    |> case do
      {:ok, category} ->
        {:noreply, show_envelope_modal(socket, %Envelope{}, category)}

      {:error, :not_found} ->
        send(self(), {:put_flash, :error, "Category not found"})
        {:noreply, socket}

      {:error, :unauthorized} ->
        send(self(), {:put_flash, :error, "You don't have permission to access this category"})
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("cancel_envelope", _params, socket) do
    {:noreply, hide_envelope_modal(socket)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("cancel_envelope_form", _params, socket) do
    {:noreply, hide_envelope_modal(socket)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate_envelope", %{"envelope" => envelope_params}, socket) do
    changeset = Budgeting.change_envelope(%Envelope{}, envelope_params)
    {:noreply, assign(socket, :envelope_form, to_form(changeset, action: :validate))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save_envelope", %{"envelope" => envelope_params}, socket) do
    envelope = socket.assigns.editing_envelope
    category = socket.assigns.selected_category_for_envelope

    if envelope && envelope.id do
      socket.assigns.current_scope
      |> Budgeting.update_envelope(socket.assigns.workspace, envelope, envelope_params)
      |> case do
        {:ok, updated_envelope} ->
          handle_successful_envelope_update(socket, category, updated_envelope)

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, :envelope_form, to_form(changeset))}

        {:error, :unauthorized} ->
          send(self(), {:put_flash, :error, "You don't have permission to update envelopes"})
          {:noreply, hide_envelope_modal(socket)}
      end
    else
      socket.assigns.current_scope
      |> Budgeting.create_envelope(socket.assigns.workspace, category, envelope_params)
      |> case do
        {:ok, envelope} ->
          updated_category = %{
            category
            | envelopes: [envelope | category.envelopes]
          }

          socket =
            socket
            |> stream_insert(:categories, updated_category)
            |> hide_envelope_modal()

          send(self(), {:put_flash, :info, "Envelope created successfully"})
          {:noreply, socket}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, :envelope_form, to_form(changeset))}

        {:error, :unauthorized} ->
          send(self(), {:put_flash, :error, "You don't have permission to create envelopes"})
          {:noreply, hide_envelope_modal(socket)}
      end
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("edit_envelope", %{"id" => external_id}, socket) do
    socket.assigns.current_scope
    |> Budgeting.fetch_envelope_by_external_id(socket.assigns.workspace, external_id, preload: [category: [:envelopes]])
    |> case do
      {:ok, envelope} ->
        {:noreply, show_envelope_modal(socket, envelope, envelope.category)}

      {:error, :not_found} ->
        send(self(), {:put_flash, :error, "Envelope not found"})
        {:noreply, socket}

      {:error, :unauthorized} ->
        send(self(), {:put_flash, :error, "You don't have permission to edit this envelope"})
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("delete_envelope_confirm", %{"id" => external_id}, socket) do
    socket.assigns.current_scope
    |> Budgeting.fetch_envelope_by_external_id(socket.assigns.workspace, external_id, preload: [category: [:envelopes]])
    |> case do
      {:ok, envelope} ->
        {:noreply, show_delete_modal(socket, envelope, :envelope)}

      {:error, :not_found} ->
        send(self(), {:put_flash, :error, "Envelope not found"})
        {:noreply, socket}

      {:error, :unauthorized} ->
        send(self(), {:put_flash, :error, "You don't have permission to delete this envelope"})
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("delete_envelope", %{"id" => _external_id}, socket) do
    envelope = socket.assigns.envelope_to_delete
    category = socket.assigns.selected_category_for_envelope

    socket.assigns.current_scope
    |> Budgeting.delete_envelope(socket.assigns.workspace, envelope)
    |> case do
      {:ok, deleted_envelope} ->
        updated_envelopes = Enum.reject(category.envelopes, fn e -> e.id == deleted_envelope.id end)
        updated_category = %{category | envelopes: updated_envelopes}

        socket =
          socket
          |> stream_insert(:categories, updated_category)
          |> hide_envelope_modal()
          |> hide_delete_modal()

        send(self(), {:put_flash, :info, "Envelope deleted successfully"})
        {:noreply, socket}

      {:error, :unauthorized} ->
        send(self(), {:put_flash, :error, "You don't have permission to delete this envelope"})

        {:noreply,
         socket
         |> hide_envelope_modal()
         |> hide_delete_modal()}

      {:error, _reason} ->
        send(self(), {:put_flash, :error, "Error deleting envelope"})

        {:noreply,
         socket
         |> hide_envelope_modal()
         |> hide_delete_modal()}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("reposition_envelope", params, socket) do
    envelope_id = params["envelope_id"]
    target_category_id = params["target_category_id"]
    prev_envelope_id = params["prev_envelope_id"]
    next_envelope_id = params["next_envelope_id"]

    case RepositionEnvelope.call(
           socket.assigns.current_scope,
           envelope_id,
           target_category_id,
           prev_envelope_id,
           next_envelope_id
         ) do
      {:ok, _updated_envelope} ->
        {:reply, %{success: true}, socket}

      {:error, :unauthorized} ->
        send(self(), {:put_flash, :error, "You don't have permission to reposition envelopes"})
        {:reply, %{error: "You don't have permission to reposition envelopes"}, socket}

      {:error, :not_found} ->
        send(self(), {:put_flash, :error, "Envelope or category not found"})
        {:reply, %{error: "Envelope or category not found"}, socket}

      {:error, _reason} ->
        send(self(), {:put_flash, :error, "Failed to save envelope position. Please try again."})
        {:reply, %{error: "Failed to save position"}, socket}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("reposition_category", params, socket) do
    category_id = params["category_id"]
    prev_category_id = params["prev_category_id"]
    next_category_id = params["next_category_id"]

    case RepositionCategory.call(
           socket.assigns.current_scope,
           category_id,
           prev_category_id,
           next_category_id
         ) do
      {:ok, _updated_category} ->
        {:reply, %{success: true}, socket}

      {:error, :unauthorized} ->
        send(self(), {:put_flash, :error, "You don't have permission to reposition categories"})
        {:reply, %{error: "You don't have permission to reposition categories"}, socket}

      {:error, :not_found} ->
        send(self(), {:put_flash, :error, "Category not found"})
        {:reply, %{error: "Category not found"}, socket}

      {:error, _reason} ->
        send(self(), {:put_flash, :error, "Failed to save category position. Please try again."})
        {:reply, %{error: "Failed to save position"}, socket}
    end
  end

  # Handle PubSub events forwarded from parent
  def handle_category_repositioned(socket) do
    categories =
      Budgeting.list_categories(socket.assigns.current_scope, socket.assigns.workspace, preload: [:envelopes])

    stream(socket, :categories, categories, reset: true)
  end

  def handle_envelope_repositioned(socket, %{category_id: category_id}) do
    case CategoryRepository.fetch(category_id, preload: [:envelopes]) do
      {:ok, updated_category} ->
        stream_insert(socket, :categories, updated_category)

      {:error, :not_found} ->
        socket
    end
  end

  def handle_envelope_removed(socket, %{category_id: category_id}) do
    case CategoryRepository.fetch(category_id, preload: [:envelopes]) do
      {:ok, updated_category} ->
        stream_insert(socket, :categories, updated_category)

      {:error, :not_found} ->
        socket
    end
  end

  # Private helper functions
  defp handle_category_deletion(socket, category) do
    if Enum.empty?(category.envelopes) do
      case Budgeting.delete_category(socket.assigns.current_scope, socket.assigns.workspace, category) do
        {:ok, deleted_category} ->
          socket =
            socket
            |> stream_delete(:categories, deleted_category)
            |> hide_delete_modal()

          send(self(), {:put_flash, :info, "Category deleted successfully"})
          {:ok, socket}

        {:error, :unauthorized} ->
          send(self(), {:put_flash, :error, "You don't have permission to delete this category"})
          {:ok, hide_delete_modal(socket)}

        {:error, _reason} ->
          send(self(), {:put_flash, :error, "Error deleting category"})
          {:ok, hide_delete_modal(socket)}
      end
    else
      send(self(), {:put_flash, :error, "Cannot delete a category with envelopes"})
      {:ok, socket}
    end
  end

  defp handle_successful_envelope_update(socket, category, updated_envelope) do
    updated_envelopes =
      Enum.map(category.envelopes, fn e ->
        if e.id == updated_envelope.id, do: updated_envelope, else: e
      end)

    updated_category = %{category | envelopes: updated_envelopes}

    socket =
      socket
      |> stream_insert(:categories, updated_category)
      |> hide_envelope_modal()

    send(self(), {:put_flash, :info, "Envelope updated successfully"})
    {:noreply, socket}
  end

  defp show_category_modal(socket, category \\ %Category{}) do
    {title, action, button} =
      if category.id do
        {"Edit Category", "save_category", "Update"}
      else
        {"Add New Category", "save_category", "Create"}
      end

    socket
    |> assign(:editing_category, category)
    |> assign(:category_form, to_form(Budgeting.change_category(category)))
    |> assign(:modal_title, title)
    |> assign(:modal_action, action)
    |> assign(:modal_button, button)
    |> assign(:category_modal_open, true)
  end

  defp hide_category_modal(socket) do
    socket
    |> assign(:category_modal_open, false)
    |> assign(:editing_category, nil)
    |> assign(:category_form, to_form(Budgeting.change_category(%Category{})))
    |> assign(:modal_title, "Add New Category")
    |> assign(:modal_action, "save_category")
    |> assign(:modal_button, "Create")
  end

  defp show_envelope_modal(socket, envelope, category) do
    {title, action, button} =
      if envelope.id do
        {"Edit Envelope", "save_envelope", "Update"}
      else
        {"Add New Envelope", "save_envelope", "Create"}
      end

    socket
    |> assign(:editing_envelope, envelope)
    |> assign(:selected_category_for_envelope, category)
    |> assign(:envelope_form, to_form(Budgeting.change_envelope(envelope)))
    |> assign(:envelope_modal_title, title)
    |> assign(:envelope_modal_action, action)
    |> assign(:envelope_modal_button, button)
    |> assign(:envelope_modal_open, true)
  end

  defp hide_envelope_modal(socket) do
    socket
    |> assign(:envelope_modal_open, false)
    |> assign(:editing_envelope, nil)
    |> assign(:selected_category_for_envelope, nil)
    |> assign(:envelope_form, to_form(Budgeting.change_envelope(%Envelope{})))
    |> assign(:envelope_modal_title, "Add New Envelope")
    |> assign(:envelope_modal_action, "save_envelope")
    |> assign(:envelope_modal_button, "Create")
  end

  defp show_delete_modal(socket, item, type) do
    case type do
      :category ->
        socket
        |> assign(:category_to_delete, item)
        |> assign(:delete_modal_open, true)

      :envelope ->
        socket
        |> assign(:envelope_to_delete, item)
        |> assign(:selected_category_for_envelope, item.category)
        |> assign(:delete_modal_open, true)
    end
  end

  defp hide_delete_modal(socket) do
    socket
    |> assign(:delete_modal_open, false)
    |> assign(:category_to_delete, nil)
    |> assign(:envelope_to_delete, nil)
    |> assign(:selected_category_for_envelope, nil)
  end

  defp handle_category_update(socket, category, category_params) do
    socket.assigns.current_scope
    |> Budgeting.update_category(socket.assigns.workspace, category, category_params, preload: [:envelopes])
    |> handle_category_result(socket, "Category updated successfully")
  end

  defp handle_category_create(socket, category_params) do
    socket.assigns.current_scope
    |> Budgeting.create_category(socket.assigns.workspace, category_params)
    |> handle_category_result(socket, "Category created successfully", at: 0)
  end

  defp handle_category_result(result, socket, success_message, opts \\ [])

  defp handle_category_result({:ok, category}, socket, success_message, opts) do
    category = if opts[:at] == 0, do: %{category | envelopes: []}, else: category
    stream_opts = if opts[:at], do: [at: opts[:at]], else: []

    socket =
      socket
      |> stream_insert(:categories, category, stream_opts)
      |> hide_category_modal()

    send(self(), {:put_flash, :info, success_message})
    {:noreply, socket}
  end

  defp handle_category_result({:error, %Ecto.Changeset{} = changeset}, socket, _success_message, _opts) do
    {:noreply, assign(socket, :category_form, to_form(changeset))}
  end

  defp handle_category_result({:error, :unauthorized}, socket, _success_message, _opts) do
    error_message =
      if socket.assigns.editing_category && socket.assigns.editing_category.id do
        "You don't have permission to update categories"
      else
        "You don't have permission to create categories"
      end

    send(self(), {:put_flash, :error, error_message})
    {:noreply, hide_category_modal(socket)}
  end

  defp handle_category_result({:error, _message}, socket, _success_message, _opts) do
    send(self(), {:put_flash, :error, "Unable to create category"})
    {:noreply, hide_category_modal(socket)}
  end

  defp subscribe_to_categories(categories) do
    Enum.each(categories, fn category ->
      PubSub.subscribe_category(category.external_id)
    end)
  end

  defp reload_categories(socket) do
    case Budgeting.list_categories(socket.assigns.current_scope, socket.assigns.workspace, preload: [:envelopes]) do
      categories when is_list(categories) ->
        stream(socket, :categories, categories, reset: true)

      {:error, :unauthorized} ->
        send(self(), {:put_flash, :error, "You don't have permission to view categories"})
        socket
    end
  end
end
