defmodule PurseCraft.TestHelpers.IdentityHelper do
  @moduledoc """
  Test helpers for the `Identity` context.
  """

  import Ecto.Query
  import PurseCraft.IdentityFactory

  alias PurseCraft.Identity
  alias PurseCraft.Identity.Schemas.UserToken
  alias PurseCraft.Repo

  def set_password(user) do
    {:ok, user, _expired_tokens} =
      Identity.update_user_password(user, %{password: valid_password()})

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def override_token_inserted_at(token, inserted_at) when is_binary(token) do
    Repo.update_all(
      from(t in UserToken,
        where: t.token == ^token
      ),
      set: [inserted_at: inserted_at]
    )
  end

  def generate_user_magic_link_token(user) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    {encoded_token, user_token.token}
  end
end
