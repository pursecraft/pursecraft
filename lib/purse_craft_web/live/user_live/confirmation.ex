defmodule PurseCraftWeb.UserLive.Confirmation do
  @moduledoc false
  use PurseCraftWeb, :live_view

  alias PurseCraft.Identity
  alias PurseCraftWeb.CoreComponents

  def render(assigns) do
    ~H"""
    <Layouts.marketing flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <CoreComponents.header class="text-center">Welcome {@user.email}</CoreComponents.header>

        <.form
          :if={!@user.confirmed_at}
          for={@form}
          id="confirmation_form"
          phx-submit="submit"
          action={~p"/users/log-in?_action=confirmed"}
          phx-trigger-action={@trigger_submit}
        >
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <CoreComponents.input
            :if={!@current_scope}
            field={@form[:remember_me]}
            type="checkbox"
            label="Keep me logged in"
          />
          <CoreComponents.button variant="primary" phx-disable-with="Confirming..." class="w-full">
            Confirm my account
          </CoreComponents.button>
        </.form>

        <.form
          :if={@user.confirmed_at}
          for={@form}
          id="login_form"
          phx-submit="submit"
          action={~p"/users/log-in"}
          phx-trigger-action={@trigger_submit}
        >
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <CoreComponents.input
            :if={!@current_scope}
            field={@form[:remember_me]}
            type="checkbox"
            label="Keep me logged in"
          />
          <CoreComponents.button variant="primary" phx-disable-with="Logging in..." class="w-full">
            Log in
          </CoreComponents.button>
        </.form>

        <p :if={!@user.confirmed_at} class="alert alert-outline mt-8">
          Tip: If you prefer passwords, you can enable them in the user settings.
        </p>
      </div>
    </Layouts.marketing>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    if user = Identity.get_user_by_magic_link_token(token) do
      form = to_form(%{"token" => token}, as: "user")

      {:ok, assign(socket, user: user, form: form, trigger_submit: false), temporary_assigns: [form: nil]}
    else
      {:ok,
       socket
       |> put_flash(:error, "Magic link is invalid or it has expired.")
       |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  def handle_event("submit", %{"user" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "user"), trigger_submit: true)}
  end
end
