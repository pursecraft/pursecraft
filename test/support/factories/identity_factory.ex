defmodule PurseCraft.IdentityFactory do
  @moduledoc false
  use PurseCraft.FactoryTemplate

  alias PurseCraft.Identity.Schemas.User
  alias PurseCraft.Identity.Schemas.UserToken

  def unconfirmed_user_factory do
    %User{
      email: valid_email()
    }
  end

  def user_factory(attrs) do
    unconfirmed_user = build(:unconfirmed_user, attrs)

    build(:user_token, %{
      context: "login",
      sent_to: unconfirmed_user.email,
      user_id: unconfirmed_user.id
    })

    struct!(
      unconfirmed_user,
      %{
        confirmed_at: DateTime.utc_now(:second)
      }
    )
  end

  def user_token_factory do
    token = :crypto.strong_rand_bytes(UserToken.rand_size())

    %UserToken{token: token}
  end
end
