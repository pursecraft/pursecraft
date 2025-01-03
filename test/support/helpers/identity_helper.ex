defmodule PurseCraft.TestHelpers.IdentityHelper do
  alias PurseCraft.Identity.Schemas.User
  alias PurseCraft.Repo

  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: Faker.Internet.email(),
      password: valid_user_password()
    })
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def get_user!(id), do: Repo.get!(User, id)
end
