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

    user_token = %UserToken{token: token}

    user_token
    |> put_hashed_fields()
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  defp put_hashed_fields(%UserToken{sent_to: nil} = user_token), do: user_token

  defp put_hashed_fields(%UserToken{sent_to: sent_to} = user_token) when is_binary(sent_to) do
    %{user_token | sent_to_hash: String.downcase(sent_to)}
  end

  defp put_hashed_fields(user_token), do: user_token
end
