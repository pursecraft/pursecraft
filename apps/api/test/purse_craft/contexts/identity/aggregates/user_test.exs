defmodule PurseCraft.Identity.Aggregates.UserTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Aggregates.User
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

  @now DateTime.utc_now(:second)

  describe "execute/2 - RegisterUser" do
    test "creates UserRegistered event for new user" do
      user_uuid = Commanded.UUID.uuid4()

      command = %RegisterUser{
        user_uuid: user_uuid,
        email: "test@example.com",
        password: "SecurePassword123!"
      }

      assert {:ok, %UserRegistered{user_uuid: ^user_uuid, email: "test@example.com"}} =
               User.execute(%User{uuid: nil}, command)
    end

    test "creates UserRegistered event without password" do
      user_uuid = Commanded.UUID.uuid4()

      command = %RegisterUser{
        user_uuid: user_uuid,
        email: "test@example.com",
        password: nil
      }

      assert {:ok, %UserRegistered{user_uuid: ^user_uuid, hashed_password: nil}} =
               User.execute(%User{uuid: nil}, command)
    end

    test "returns error when user already exists" do
      user_uuid = Commanded.UUID.uuid4()

      command = %RegisterUser{
        user_uuid: user_uuid,
        email: "test@example.com"
      }

      assert {:error, :already_registered} = User.execute(%User{uuid: user_uuid}, command)
    end
  end

  describe "execute/2 - CreateUserPassword" do
    test "creates UserPasswordCreated event for user without password" do
      user = %User{uuid: Commanded.UUID.uuid4(), hashed_password: nil}

      command = %CreateUserPassword{
        user_uuid: user.uuid,
        password: "SecurePassword123!",
        password_confirmation: "SecurePassword123!"
      }

      assert {:ok, %UserPasswordCreated{}} = User.execute(user, command)
    end

    test "returns error when passwords don't match" do
      user = %User{uuid: Commanded.UUID.uuid4(), hashed_password: nil}

      command = %CreateUserPassword{
        user_uuid: user.uuid,
        password: "SecurePassword123!",
        password_confirmation: "DifferentPassword123!"
      }

      assert {:error, :passwords_dont_match} = User.execute(user, command)
    end

    test "returns error when user already has a password" do
      user = %User{
        uuid: Commanded.UUID.uuid4(),
        hashed_password: "hashed_password_here"
      }

      command = %CreateUserPassword{
        user_uuid: user.uuid,
        password: "SecurePassword123!",
        password_confirmation: "SecurePassword123!"
      }

      assert {:error, :password_already_set} = User.execute(user, command)
    end
  end

  describe "execute/2 - ConfirmUserEmail" do
    test "creates UserEmailConfirmed event when email is not confirmed" do
      user = %User{
        uuid: Commanded.UUID.uuid4(),
        email: "test@example.com",
        confirmed_at: nil
      }

      confirmed_at = DateTime.utc_now(:second)
      command = %ConfirmUserEmail{user_uuid: user.uuid, confirmed_at: confirmed_at}

      assert {:ok, %UserEmailConfirmed{confirmed_at: ^confirmed_at}} = User.execute(user, command)
    end

    test "returns error when email is already confirmed" do
      user = %User{
        uuid: Commanded.UUID.uuid4(),
        email: "test@example.com",
        confirmed_at: DateTime.utc_now()
      }

      command = %ConfirmUserEmail{user_uuid: user.uuid, confirmed_at: DateTime.utc_now()}

      assert {:error, :already_confirmed} = User.execute(user, command)
    end
  end

  describe "execute/2 - RequestEmailChange" do
    test "creates UserEmailChangeRequested event for different email" do
      user = %User{
        uuid: Commanded.UUID.uuid4(),
        email: "old@example.com"
      }

      command = %RequestEmailChange{
        user_uuid: user.uuid,
        new_email: "new@example.com"
      }

      assert {:ok, %UserEmailChangeRequested{new_email: "new@example.com"}} =
               User.execute(user, command)
    end

    test "returns error when new email is same as current" do
      user = %User{
        uuid: Commanded.UUID.uuid4(),
        email: "test@example.com"
      }

      command = %RequestEmailChange{
        user_uuid: user.uuid,
        new_email: "test@example.com"
      }

      assert {:error, :same_email} = User.execute(user, command)
    end
  end

  describe "execute/2 - UpdateUserPassword" do
    setup do
      user_uuid = Commanded.UUID.uuid4()
      hashed_password = Bcrypt.hash_pwd_salt("CurrentPassword123!")

      user = %User{
        uuid: user_uuid,
        email: "test@example.com",
        hashed_password: hashed_password
      }

      %{user: user}
    end

    test "creates UserPasswordUpdated event with valid credentials", %{user: user} do
      command = %UpdateUserPassword{
        user_uuid: user.uuid,
        current_password: "CurrentPassword123!",
        new_password: "NewSecurePassword456!",
        password_confirmation: "NewSecurePassword456!"
      }

      assert {:ok, %UserPasswordUpdated{}} = User.execute(user, command)
    end

    test "returns error when current password is invalid", %{user: user} do
      command = %UpdateUserPassword{
        user_uuid: user.uuid,
        current_password: "WrongPassword123!",
        new_password: "NewSecurePassword456!",
        password_confirmation: "NewSecurePassword456!"
      }

      assert {:error, :invalid_current_password} = User.execute(user, command)
    end

    test "returns error when new passwords don't match", %{user: user} do
      command = %UpdateUserPassword{
        user_uuid: user.uuid,
        current_password: "CurrentPassword123!",
        new_password: "NewSecurePassword456!",
        password_confirmation: "DifferentPassword456!"
      }

      assert {:error, :passwords_dont_match} = User.execute(user, command)
    end

    test "returns error when user has no password" do
      user = %User{
        uuid: Commanded.UUID.uuid4(),
        hashed_password: nil
      }

      command = %UpdateUserPassword{
        user_uuid: user.uuid,
        current_password: "DoesntMatter123!",
        new_password: "NewSecurePassword456!",
        password_confirmation: "NewSecurePassword456!"
      }

      assert {:error, :no_password_set} = User.execute(user, command)
    end
  end

  describe "apply_event/2" do
    test "applies UserRegistered event" do
      user = %User{uuid: nil}

      event = %UserRegistered{
        user_uuid: "user-123",
        email: "test@example.com",
        hashed_password: "hashed",
        confirmed_at: nil
      }

      result = User.apply_event(user, event)

      assert result.uuid == "user-123"
      assert result.email == "test@example.com"
      assert result.hashed_password == "hashed"
      assert result.confirmed_at == nil
    end

    test "applies UserPasswordCreated event" do
      user = %User{uuid: "user-123"}

      event = %UserPasswordCreated{
        user_uuid: "user-123",
        hashed_password: "new_hashed"
      }

      result = User.apply_event(user, event)

      assert result.hashed_password == "new_hashed"
    end

    test "applies UserEmailConfirmed event" do
      user = %User{
        uuid: "user-123",
        confirmed_at: nil
      }

      event = %UserEmailConfirmed{
        user_uuid: "user-123",
        email: "test@example.com",
        confirmed_at: @now
      }

      result = User.apply_event(user, event)

      assert result.confirmed_at == @now
    end

    test "applies UserEmailChangeRequested event" do
      user = %User{
        uuid: "user-123",
        email: "old@example.com"
      }

      event = %UserEmailChangeRequested{
        user_uuid: "user-123",
        current_email: "old@example.com",
        new_email: "new@example.com"
      }

      result = User.apply_event(user, event)

      assert result.pending_email == "new@example.com"
    end

    test "applies UserEmailChanged event" do
      user = %User{
        uuid: "user-123",
        email: "old@example.com",
        pending_email: "new@example.com"
      }

      event = %UserEmailChanged{
        user_uuid: "user-123",
        old_email: "old@example.com",
        new_email: "new@example.com"
      }

      result = User.apply_event(user, event)

      assert result.email == "new@example.com"
      assert result.pending_email == nil
    end

    test "applies UserPasswordUpdated event" do
      user = %User{
        uuid: "user-123",
        failed_login_attempts: 3,
        locked_until: DateTime.add(DateTime.utc_now(), 3600)
      }

      event = %UserPasswordUpdated{
        user_uuid: "user-123"
      }

      result = User.apply_event(user, event)

      assert result.failed_login_attempts == 0
      assert result.locked_until == nil
    end
  end

  describe "state transitions" do
    test "user lifecycle from registration to password change" do
      user_uuid = Commanded.UUID.uuid4()

      # Register user
      {:ok, registered_event} =
        User.execute(
          %User{uuid: nil},
          %RegisterUser{
            user_uuid: user_uuid,
            email: "test@example.com",
            password: "InitialPassword123!"
          }
        )

      registered_user = User.apply_event(%User{uuid: nil}, registered_event)
      assert registered_user.uuid == user_uuid
      assert registered_user.email == "test@example.com"
      assert registered_user.hashed_password

      # Confirm email
      {:ok, confirmed_event} =
        User.execute(registered_user, %ConfirmUserEmail{
          user_uuid: user_uuid,
          confirmed_at: DateTime.utc_now(:second)
        })

      confirmed_user = User.apply_event(registered_user, confirmed_event)
      assert %DateTime{} = confirmed_user.confirmed_at

      # Update password
      {:ok, updated_event} =
        User.execute(
          confirmed_user,
          %UpdateUserPassword{
            user_uuid: user_uuid,
            current_password: "InitialPassword123!",
            new_password: "NewPassword456!",
            password_confirmation: "NewPassword456!"
          }
        )

      final_user = User.apply_event(confirmed_user, updated_event)
      assert final_user.failed_login_attempts == 0
    end
  end
end
