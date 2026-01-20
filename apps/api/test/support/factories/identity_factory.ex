defmodule PurseCraft.IdentityFactory do
  @moduledoc """
  Factories for Identity context.
  """

  defmacro __using__(_opts) do
    quote do
      def identity_user_factory do
        %PurseCraft.Identity.User{
          email: sequence(:identity_user_email, &"user#{&1}@example.com"),
          confirmed_at: nil
        }
      end

      def identity_confirmed_user_factory do
        struct!(
          identity_user_factory(),
          confirmed_at: DateTime.utc_now(:second)
        )
      end

      def identity_user_with_password_factory do
        password = "hello world!"

        %PurseCraft.Identity.User{
          email: sequence(:identity_user_with_password_email, &"password_user#{&1}@example.com"),
          password: password,
          hashed_password: Bcrypt.hash_pwd_salt(password),
          confirmed_at: DateTime.utc_now(:second)
        }
      end

      def identity_user_with_scope_factory do
        user = identity_confirmed_user_factory()
        scope = PurseCraft.Identity.Scope.for_user(user)

        {user, scope}
      end

      def identity_user_token_factory do
        user = build(:identity_user)

        {token, user_token} =
          PurseCraft.Identity.UserToken.build_email_token(user, "login")

        user_token
      end

      @doc """
      Helper to extract token from captured email for testing.
      """
      def identity_extract_user_token(fun) do
        {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
        [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
        token
      end

      @doc """
      Generates and inserts a magic link token for a user.
      Returns {encoded_token, hashed_token}.
      """
      def identity_user_magic_link_token(user) do
        {encoded_token, user_token} =
          PurseCraft.Identity.UserToken.build_email_token(user, "login")

        PurseCraft.Repo.insert!(user_token)

        {encoded_token, user_token.token}
      end
    end
  end
end
