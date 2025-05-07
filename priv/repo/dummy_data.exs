# Script for populating the database with dummy data. You can run it as:
#
#     mix run priv/repo/dummy_data.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     PurseCraft.Repo.insert!(%PurseCraft.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias PurseCraft.Repo
alias PurseCraft.Budgeting.Schemas.Book
alias PurseCraft.Budgeting.Schemas.BookUser
alias PurseCraft.Identity.Schemas.User

IO.puts("--------------------------------")
IO.puts("|     CREATING DUMMY DATA      |")
IO.puts("--------------------------------")

now = DateTime.utc_now(:second)
password = "password123!"
hashed_password = Bcrypt.hash_pwd_salt(password)

dummy_book = Repo.insert!(%Book{
  name: "Dummy Book"
})

dummy_book_owner = Repo.insert!(%User{
  email: "owner@example.com",
  hashed_password: hashed_password,
  confirmed_at: now,
  authenticated_at: now
})

dummy_book_editor = Repo.insert!(%User{
  email: "editor@example.com",
  hashed_password: hashed_password,
  confirmed_at: now,
  authenticated_at: now
})

dummy_book_commenter = Repo.insert!(%User{
  email: "commenter@example.com",
  hashed_password: hashed_password,
  confirmed_at: now,
  authenticated_at: now
})

Repo.insert!(%BookUser{
  book_id: dummy_book.id,
  user_id: dummy_book_owner.id,
  role: :owner
})

Repo.insert!(%BookUser{
  book_id: dummy_book.id,
  user_id: dummy_book_editor.id,
  role: :editor
})

Repo.insert!(%BookUser{
  book_id: dummy_book.id,
  user_id: dummy_book_commenter.id,
  role: :commenter
})

Process.sleep(1)

IO.puts("--------------------------------")
IO.puts("| FINISHED CREATING DUMMY DATA |")
IO.puts("--------------------------------")
