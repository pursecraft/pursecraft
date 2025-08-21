defmodule PurseCraft.IdentityFactory do
  @moduledoc false
  use PurseCraft.FactoryTemplate

  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Identity.Schemas.User
  alias PurseCraft.Identity.Schemas.UserToken

  def scope_factory do
    %Scope{}
  end

  def unconfirmed_user_factory(attrs) do
    email = Map.get(attrs, :email, valid_email())

    user =
      %User{}
      |> User.email_changeset(%{email: email})
      |> Ecto.Changeset.apply_changes()

    user
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  def user_factory(attrs) do
    unconfirmed_user = build(:unconfirmed_user, attrs)

    build(:user_token, %{
      context: "login",
      sent_to: unconfirmed_user.email,
      user_id: unconfirmed_user.id
    })

    user = struct!(unconfirmed_user, %{confirmed_at: DateTime.utc_now(:second)})

    user
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  def user_token_factory(attrs) do
    token = :crypto.strong_rand_bytes(UserToken.rand_size())
    sent_to = Map.get(attrs, :sent_to)

    base_token = %UserToken{token: token}

    user_token =
      if sent_to do
        base_token
        |> UserToken.changeset(%{sent_to: sent_to})
        |> Ecto.Changeset.apply_changes()
      else
        base_token
      end

    user_token
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end
end
