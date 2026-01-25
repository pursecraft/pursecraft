defmodule PurseCraft.Identity.Aggregates.User do
  @moduledoc false
  alias PurseCraft.Identity.Commands.ConfirmUserEmail
  alias PurseCraft.Identity.Commands.CreateUserPassword
  alias PurseCraft.Identity.Commands.RegisterUser
  alias PurseCraft.Identity.Commands.RequestEmailChange
  alias PurseCraft.Identity.Commands.UpdateUserPassword
  alias PurseCraft.Identity.Events.UserEmailChanged
  alias PurseCraft.Identity.Events.UserEmailChangeRequested
  alias PurseCraft.Identity.Events.UserEmailConfirmed
  alias PurseCraft.Identity.Events.UserPasswordCreated
  alias PurseCraft.Identity.Events.UserPasswordUpdated
  alias PurseCraft.Identity.Events.UserRegistered

  defstruct [
    :uuid,
    :email,
    :hashed_password,
    :confirmed_at,
    :pending_email,
    :failed_login_attempts,
    :locked_until
  ]

  @type t :: %__MODULE__{
          uuid: String.t() | nil,
          email: String.t() | nil,
          hashed_password: String.t() | nil,
          confirmed_at: DateTime.t() | nil,
          pending_email: String.t() | nil,
          failed_login_attempts: non_neg_integer(),
          locked_until: DateTime.t() | nil
        }

  @spec execute(t(), struct()) :: {:ok, struct()} | {:error, atom()}

  def execute(%__MODULE__{uuid: nil}, %RegisterUser{} = command) do
    event = %UserRegistered{
      user_uuid: command.user_uuid,
      email: command.email,
      hashed_password: hash_password(command.password),
      confirmed_at: nil
    }

    {:ok, event}
  end

  def execute(%__MODULE__{uuid: _uuid}, %RegisterUser{}) do
    {:error, :already_registered}
  end

  def execute(%__MODULE__{hashed_password: nil} = user, %CreateUserPassword{} = command) do
    with :ok <- validate_password_confirmation(command) do
      event = %UserPasswordCreated{
        user_uuid: user.uuid,
        hashed_password: hash_password(command.password)
      }

      {:ok, event}
    end
  end

  def execute(%__MODULE__{hashed_password: hashed_password}, %CreateUserPassword{}) when is_binary(hashed_password) do
    {:error, :password_already_set}
  end

  def execute(%__MODULE__{confirmed_at: nil} = user, %ConfirmUserEmail{} = command) do
    event = %UserEmailConfirmed{
      user_uuid: user.uuid,
      email: user.email,
      confirmed_at: command.confirmed_at
    }

    {:ok, event}
  end

  def execute(%__MODULE__{confirmed_at: confirmed_at}, %ConfirmUserEmail{}) when not is_nil(confirmed_at) do
    {:error, :already_confirmed}
  end

  def execute(%__MODULE__{} = user, %RequestEmailChange{} = command) do
    if command.new_email == user.email do
      {:error, :same_email}
    else
      event = %UserEmailChangeRequested{
        user_uuid: user.uuid,
        current_email: user.email,
        new_email: command.new_email
      }

      {:ok, event}
    end
  end

  def execute(%__MODULE__{} = user, %UpdateUserPassword{} = command) do
    with :ok <- validate_current_password(user, command.current_password),
         :ok <- validate_password_confirmation(command) do
      event = %UserPasswordUpdated{
        user_uuid: user.uuid
      }

      {:ok, event}
    end
  end

  @spec apply_event(t(), struct()) :: t()

  def apply_event(%__MODULE__{} = user, %UserRegistered{} = event) do
    %{
      user
      | uuid: event.user_uuid,
        email: event.email,
        hashed_password: event.hashed_password,
        confirmed_at: event.confirmed_at
    }
  end

  def apply_event(%__MODULE__{} = user, %UserPasswordCreated{} = event) do
    %{user | hashed_password: event.hashed_password}
  end

  def apply_event(%__MODULE__{} = user, %UserEmailConfirmed{} = event) do
    %{user | confirmed_at: event.confirmed_at}
  end

  def apply_event(%__MODULE__{} = user, %UserEmailChangeRequested{} = event) do
    %{user | pending_email: event.new_email}
  end

  def apply_event(%__MODULE__{} = user, %UserEmailChanged{} = event) do
    %{user | email: event.new_email, pending_email: nil}
  end

  def apply_event(%__MODULE__{} = user, %UserPasswordUpdated{}) do
    %{user | failed_login_attempts: 0, locked_until: nil}
  end

  defp hash_password(nil), do: nil
  defp hash_password(password), do: Bcrypt.hash_pwd_salt(password)

  defp validate_password_confirmation(%CreateUserPassword{
         password: password,
         password_confirmation: password_confirmation
       })
       when password == password_confirmation,
       do: :ok

  defp validate_password_confirmation(%CreateUserPassword{}), do: {:error, :passwords_dont_match}

  defp validate_password_confirmation(%UpdateUserPassword{
         new_password: new_password,
         password_confirmation: password_confirmation
       })
       when new_password == password_confirmation,
       do: :ok

  defp validate_password_confirmation(%UpdateUserPassword{}), do: {:error, :passwords_dont_match}

  defp validate_current_password(%__MODULE__{hashed_password: hashed_password}, current_password)
       when is_binary(hashed_password) do
    if Bcrypt.verify_pass(current_password, hashed_password) do
      :ok
    else
      {:error, :invalid_current_password}
    end
  end

  defp validate_current_password(%__MODULE__{hashed_password: nil}, _current_password) do
    {:error, :no_password_set}
  end
end
