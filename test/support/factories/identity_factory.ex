defmodule PurseCraft.IdentityFactory do
  @moduledoc false
  use PurseCraft.FactoryTemplate

  alias PurseCraft.Identity.Schemas.Book
  alias PurseCraft.Identity.Schemas.BookUser
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
    |> UserToken.put_hashed_fields()
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  def book_factory do
    name = Faker.Pokemon.name()

    book =
      %Book{}
      |> Book.changeset(%{name: name})
      |> Ecto.Changeset.apply_changes()

    book
  end

  def book_user_factory do
    %BookUser{
      role: Enum.random([:owner, :editor, :commenter])
    }
  end
end
