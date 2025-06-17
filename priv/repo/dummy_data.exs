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
alias PurseCraft.Budgeting.Schemas.Category
alias PurseCraft.Budgeting.Schemas.Envelope
alias PurseCraft.Identity.Schemas.User
alias PurseCraft.Utilities.FractionalIndexing

import Ecto.Changeset

IO.puts("--------------------------------")
IO.puts("|     CREATING DUMMY DATA      |")
IO.puts("--------------------------------")

now = DateTime.utc_now(:second)
password = "password123!"
hashed_password = Bcrypt.hash_pwd_salt(password)

dummy_book = Repo.insert!(%Book{
  name: "Dummy Book"
})

dummy_book_owner = 
  %User{}
  |> User.email_changeset(%{email: "owner@example.com"})
  |> put_change(:hashed_password, hashed_password)
  |> put_change(:confirmed_at, now)
  |> put_change(:authenticated_at, now)
  |> Repo.insert!()

dummy_book_editor = 
  %User{}
  |> User.email_changeset(%{email: "editor@example.com"})
  |> put_change(:hashed_password, hashed_password)
  |> put_change(:confirmed_at, now)
  |> put_change(:authenticated_at, now)
  |> Repo.insert!()

dummy_book_commenter = 
  %User{}
  |> User.email_changeset(%{email: "commenter@example.com"})
  |> put_change(:hashed_password, hashed_password)
  |> put_change(:confirmed_at, now)
  |> put_change(:authenticated_at, now)
  |> Repo.insert!()

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

category_names = [
  "Housing",
  "Transportation",
  "Food",
  "Personal",
  "Lifestyle"
]

envelope_names = %{
  "Housing" => [
    "Mortgage/Rent",
    "Property Tax",
    "Home Insurance",
    "Utilities",
    "Internet",
    "Phone",
    "Maintenance",
    "Furniture",
    "Decorations",
    "Improvements"
  ],
  "Transportation" => [
    "Car Payment", 
    "Gas",
    "Car Insurance",
    "Maintenance",
    "Public Transit",
    "Uber/Lyft",
    "Parking",
    "Tolls",
    "Registration",
    "Car Wash"
  ],
  "Food" => [
    "Groceries",
    "Dining Out",
    "Coffee Shops",
    "Fast Food",
    "Work Lunches",
    "Alcohol",
    "Snacks",
    "Specialty Foods",
    "Meal Kits",
    "Food Delivery"
  ],
  "Personal" => [
    "Clothing",
    "Shoes",
    "Haircuts",
    "Cosmetics",
    "Gym Membership",
    "Medicine",
    "Doctor Visits",
    "Dentist",
    "Vision",
    "Self-care"
  ],
  "Lifestyle" => [
    "Entertainment",
    "Streaming Services",
    "Hobbies",
    "Books",
    "Music",
    "Gifts",
    "Pets",
    "Travel",
    "Education",
    "Subscriptions"
  ]
}

{:ok, positions} = FractionalIndexing.initial_positions(length(category_names))

category_names
|> Enum.zip(positions)
|> Enum.each(fn {category_name, position} ->
  category = Repo.insert!(%Category{
    name: category_name,
    book_id: dummy_book.id,
    position: position
  })

  envelope_list = envelope_names[category_name]
  {:ok, envelope_positions} = FractionalIndexing.initial_positions(length(envelope_list))

  envelope_list
  |> Enum.zip(envelope_positions)
  |> Enum.each(fn {envelope_name, envelope_position} ->
    Repo.insert!(%Envelope{
      name: envelope_name,
      category_id: category.id,
      position: envelope_position
    })
  end)
end)

Process.sleep(1)

IO.puts("--------------------------------")
IO.puts("| FINISHED CREATING DUMMY DATA |")
IO.puts("--------------------------------")
