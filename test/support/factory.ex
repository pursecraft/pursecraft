defmodule PurseCraft.Factory do
  use ExMachina.Ecto, repo: PurseCraft.Repo

  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Identity.Schemas.User
  alias PurseCraft.TestHelpers.IdentityHelper

  def book_factory do
    %Book{
      name: sequence(:name, &"book-#{&1}")
    }
  end

  def user_factory(attrs) do
    {password, attrs} = Map.pop(attrs, :password, IdentityHelper.valid_user_password())

    user = %User{
      email: Faker.Internet.email(),
      hashed_password: Bcrypt.hash_pwd_salt(password)
    }

    user
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end
end
