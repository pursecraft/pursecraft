defmodule PurseCraftWeb.Components.UI.Budgeting.Form do
  @moduledoc """
  Form components for the budgeting layout.
  Uses DaisyUI 5 form classes.
  """

  use PurseCraftWeb, :html

  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormField
  alias PurseCraftWeb.Components.UI.Budgeting.Icon

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag
    * `type="checkbox"` is used exclusively to render boolean values
    * `type="textarea"` renders a `<textarea>` tag

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               range search select tel text textarea time url week hidden)

  attr :field, FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"
  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global, include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  # TODO: Remove the coveralls-ignore because we should be using
  # in the future

  # coveralls-ignore-start
  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="form-control">
      <label class="label cursor-pointer justify-start gap-3">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="checkbox"
          {@rest}
        />
        <span :if={@label} class="label-text">{@label}</span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="form-control w-full">
      <label :if={@label} class="label">
        <span class="label-text">{@label}</span>
      </label>
      <select
        id={@id}
        name={@name}
        class={["select select-bordered w-full", @errors != [] && "select-error"]}
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="form-control w-full">
      <label :if={@label} class="label">
        <span class="label-text">{@label}</span>
      </label>
      <textarea
        id={@id}
        name={@name}
        class={["textarea textarea-bordered w-full", @errors != [] && "textarea-error"]}
        {@rest}
      >{Form.normalize_value("textarea", @value)}</textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # coveralls-ignore-stop

  def input(assigns) do
    ~H"""
    <div class="form-control w-full">
      <label :if={@label} class="label">
        <span class="label-text">{@label}</span>
      </label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Form.normalize_value(@type, @value)}
        class={["input input-bordered w-full", @errors != [] && "input-error"]}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <label class="label">
      <span class="label-text-alt text-error flex items-center gap-1">
        <Icon.icon name="exclamation-circle-mini" class="size-4" />
        {render_slot(@inner_block)}
      </span>
    </label>
    """
  end

  # TODO: Remove the coveralls-ignore because we should be using
  # in the future

  # coveralls-ignore-start

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(PurseCraftWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(PurseCraftWeb.Gettext, "errors", msg, opts)
    end
  end

  def translate_error(msg) when is_binary(msg), do: msg
  # coveralls-ignore-stop
end
