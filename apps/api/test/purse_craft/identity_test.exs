defmodule PurseCraft.IdentityTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity
  alias PurseCraft.Identity.User
  alias PurseCraft.Identity.UserToken

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Identity.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = insert(:identity_confirmed_user)
      assert %User{id: ^id} = Identity.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Identity.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = insert(:identity_user_with_password)
      refute Identity.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = insert(:identity_user_with_password)

      assert %User{id: ^id} =
               Identity.get_user_by_email_and_password(user.email, "hello world!")
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Identity.get_user!(-1)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = insert(:identity_confirmed_user)
      assert %User{id: ^id} = Identity.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email to be set" do
      {:error, changeset} = Identity.register_user(%{})

      assert %{email: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates email when given" do
      {:error, changeset} = Identity.register_user(%{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum values for email for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Identity.register_user(%{email: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness" do
      %{email: email} = insert(:identity_confirmed_user)
      {:error, changeset} = Identity.register_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the uppercased email too, to check that email case is ignored.
      {:error, uppercased_changeset} = Identity.register_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(uppercased_changeset).email
    end

    test "registers users without password" do
      email = "user#{System.unique_integer()}@example.com"
      {:ok, user} = Identity.register_user(%{email: email})
      assert user.email == email
      assert is_nil(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end
  end

  describe "sudo_mode?/2" do
    test "validates the authenticated_at time" do
      now = DateTime.utc_now()

      assert Identity.sudo_mode?(%User{authenticated_at: DateTime.utc_now()})
      assert Identity.sudo_mode?(%User{authenticated_at: DateTime.add(now, -19, :minute)})
      refute Identity.sudo_mode?(%User{authenticated_at: DateTime.add(now, -21, :minute)})

      # minute override
      refute Identity.sudo_mode?(
               %User{authenticated_at: DateTime.add(now, -11, :minute)},
               -10
             )

      # not authenticated
      refute Identity.sudo_mode?(%User{})
    end
  end

  describe "change_user_email/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Identity.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "deliver_user_update_email_instructions/3" do
    setup do
      %{user: insert(:identity_confirmed_user)}
    end

    test "sends token through notification", %{user: user} do
      encoded_token =
        identity_extract_user_token(fn url ->
          Identity.deliver_user_update_email_instructions(user, "current@example.com", url)
        end)

      {:ok, decoded_token} = Base.url_decode64(encoded_token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, decoded_token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup do
      user = insert(:identity_confirmed_user)
      email = "user" <> Integer.to_string(System.unique_integer()) <> "@example.com"

      token =
        identity_extract_user_token(fn url ->
          Identity.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{user: user, token: token, email: email}
    end

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      assert {:ok, %{email: ^email}} = Identity.update_user_email(user, token)
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user} do
      assert Identity.update_user_email(user, "invalid-base64!!!") ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      assert Identity.update_user_email(%{user | email: "current@example.com"}, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])

      assert Identity.update_user_email(user, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_user_password/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Identity.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Identity.change_user_password(
          %User{},
          %{
            "password" => "new valid password"
          },
          hash_password: false
        )

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/2" do
    setup do
      %{user: insert(:identity_confirmed_user)}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Identity.update_user_password(user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Identity.update_user_password(user, %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, {user, expired_tokens}} =
        Identity.update_user_password(user, %{
          password: "new valid password"
        })

      assert expired_tokens == []
      assert is_nil(user.password)
      assert Identity.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _token = Identity.generate_user_session_token(user)

      {:ok, {_updated_user, _expired_tokens}} =
        Identity.update_user_password(user, %{
          password: "new valid password"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: insert(:identity_confirmed_user)}
    end

    test "generates a token", %{user: user} do
      token = Identity.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"
      assert user_token.authenticated_at

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: insert(:identity_confirmed_user).id,
          context: "session"
        })
      end
    end

    test "duplicates the authenticated_at of given user in new token", %{user: user} do
      one_hour_ago =
        :second
        |> DateTime.utc_now()
        |> DateTime.add(-3600)

      old_user = %{user | authenticated_at: one_hour_ago}
      token = Identity.generate_user_session_token(old_user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.authenticated_at == old_user.authenticated_at
      assert DateTime.after?(user_token.inserted_at, old_user.authenticated_at)
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = insert(:identity_confirmed_user)
      token = Identity.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert {session_user, token_inserted_at} = Identity.get_user_by_session_token(token)
      assert session_user.id == user.id
      assert session_user.authenticated_at
      assert token_inserted_at
    end

    test "does not return user for invalid token" do
      refute Identity.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      dt = ~N[2020-01-01 00:00:00]
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: dt, authenticated_at: dt])
      refute Identity.get_user_by_session_token(token)
    end
  end

  describe "get_user_by_magic_link_token/1" do
    setup do
      user = insert(:identity_confirmed_user)
      {encoded_token, _hashed_token} = identity_user_magic_link_token(user)
      %{user: user, token: encoded_token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Identity.get_user_by_magic_link_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Identity.get_user_by_magic_link_token("invalid-base64!!!")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Identity.get_user_by_magic_link_token(token)
    end
  end

  describe "login_user_by_magic_link/1" do
    test "confirms user and expires tokens" do
      user = insert(:identity_user)
      refute user.confirmed_at
      {encoded_token, hashed_token} = identity_user_magic_link_token(user)

      assert {:ok, {user, [%{token: ^hashed_token}]}} =
               Identity.login_user_by_magic_link(encoded_token)

      assert user.confirmed_at
    end

    test "returns user and (deleted) token for confirmed user" do
      user = insert(:identity_confirmed_user)
      assert user.confirmed_at
      {encoded_token, _hashed_token} = identity_user_magic_link_token(user)
      assert {:ok, {^user, []}} = Identity.login_user_by_magic_link(encoded_token)
      # one time use only
      assert {:error, :not_found} = Identity.login_user_by_magic_link(encoded_token)
    end

    test "raises when unconfirmed user has password set" do
      user = insert(:identity_user)
      {1, nil} = Repo.update_all(User, set: [hashed_password: "hashed"])
      {encoded_token, _hashed_token} = identity_user_magic_link_token(user)

      assert_raise RuntimeError, ~r/magic link log in is not allowed/, fn ->
        Identity.login_user_by_magic_link(encoded_token)
      end
    end

    test "raises MatchError for invalid base64 token" do
      invalid_token = "not-valid-base64!!!"

      assert_raise MatchError, fn ->
        Identity.login_user_by_magic_link(invalid_token)
      end
    end
  end

  describe "delete_user_session_token/1" do
    test "deletes the token" do
      user = insert(:identity_confirmed_user)
      token = Identity.generate_user_session_token(user)
      assert Identity.delete_user_session_token(token) == :ok
      refute Identity.get_user_by_session_token(token)
    end
  end

  describe "deliver_login_instructions/2" do
    setup do
      %{user: insert(:identity_confirmed_user)}
    end

    test "sends token through notification", %{user: user} do
      encoded_token =
        identity_extract_user_token(fn url ->
          Identity.deliver_login_instructions(user, url)
        end)

      {:ok, decoded_token} = Base.url_decode64(encoded_token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, decoded_token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "login"
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
