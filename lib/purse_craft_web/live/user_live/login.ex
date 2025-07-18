defmodule PurseCraftWeb.UserLive.Login do
  @moduledoc false
  use PurseCraftWeb, :live_view

  alias PurseCraft.Identity
  alias PurseCraftWeb.CoreComponents

  def render(assigns) do
    ~H"""
    <Layouts.marketing flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <CoreComponents.header class="text-center">
          <p>Log in</p>
          <:subtitle>
            <%= if @current_scope do %>
              You need to reauthenticate to perform sensitive actions on your account.
            <% else %>
              Don't have an account? <.link
                navigate={~p"/users/register"}
                class="font-semibold text-brand hover:underline"
                phx-no-format
              >Sign up</.link> for an account now.
            <% end %>
          </:subtitle>
        </CoreComponents.header>

        <.form
          :let={f}
          for={@form}
          id="login_form_magic"
          action={~p"/users/log-in"}
          phx-submit="submit_magic"
        >
          <CoreComponents.input
            readonly={!!@current_scope}
            field={f[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            required
            phx-mounted={JS.focus()}
          />
          <CoreComponents.button class="w-full" variant="primary">
            Log in with email <span aria-hidden="true">→</span>
          </CoreComponents.button>
        </.form>

        <div class="divider">or</div>

        <.form
          :let={f}
          for={@form}
          id="login_form_password"
          action={~p"/users/log-in"}
          phx-submit="submit_password"
          phx-trigger-action={@trigger_submit}
        >
          <CoreComponents.input
            readonly={!!@current_scope}
            field={f[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            required
          />
          <CoreComponents.input
            field={@form[:password]}
            type="password"
            label="Password"
            autocomplete="current-password"
          />
          <CoreComponents.input
            :if={!@current_scope}
            field={f[:remember_me]}
            type="checkbox"
            label="Keep me logged in"
          />
          <CoreComponents.button class="w-full" variant="primary">
            Log in <span aria-hidden="true">→</span>
          </CoreComponents.button>
        </.form>

        <div :if={local_mail_adapter?()} class="alert alert-outline mt-8">
          <div>
            <p>You are running the local mail adapter.</p>
            <% # coveralls-ignore-start %>
            <p>
              To see sent emails, visit <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
            </p>
            <% # coveralls-ignore-stop %>
          </div>
        </div>
      </div>
    </Layouts.marketing>
    """
  end

  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Identity.get_user_by_email(email) do
      Identity.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:purse_craft, PurseCraft.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
