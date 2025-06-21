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

import Ecto.Changeset

alias PurseCraft.Accounting.Schemas.Account
alias PurseCraft.Identity.Schemas.Book
alias PurseCraft.Identity.Schemas.BookUser
alias PurseCraft.Budgeting.Schemas.Category
alias PurseCraft.Budgeting.Schemas.Envelope
alias PurseCraft.Identity.Schemas.User
alias PurseCraft.Repo
alias PurseCraft.Utilities.FractionalIndexing

IO.puts("--------------------------------")
IO.puts("|     CREATING DUMMY DATA      |")
IO.puts("--------------------------------")

now = DateTime.utc_now(:second)
password = "password123!"
hashed_password = Bcrypt.hash_pwd_salt(password)

dummy_book =
  %Book{}
  |> Book.changeset(%{name: "Dummy Book"})
  |> Repo.insert!()

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
  category =
    %Category{}
    |> Category.changeset(%{
      name: category_name,
      book_id: dummy_book.id,
      position: position
    })
    |> Repo.insert!()

  envelope_list = envelope_names[category_name]
  {:ok, envelope_positions} = FractionalIndexing.initial_positions(length(envelope_list))

  envelope_list
  |> Enum.zip(envelope_positions)
  |> Enum.each(fn {envelope_name, envelope_position} ->
    %Envelope{}
    |> Envelope.changeset(%{
      name: envelope_name,
      category_id: category.id,
      position: envelope_position
    })
    |> Repo.insert!()
  end)
end)

# Create dummy accounts
account_data = [
  %{name: "Chase Checking", account_type: "checking"},
  %{name: "Ally Savings", account_type: "savings"},
  %{name: "Cash Wallet", account_type: "cash"},
  %{name: "Chase Freedom Credit Card", account_type: "credit_card"},
  %{name: "Home Equity Line of Credit", account_type: "line_of_credit"},
  %{name: "Home Mortgage", account_type: "mortgage"},
  %{name: "Honda CR-V Loan", account_type: "auto_loan"},
  %{name: "Student Loans", account_type: "student_loan"},
  %{name: "Personal Loan", account_type: "personal_loan"},
  %{name: "House (Asset)", account_type: "asset"},
  %{name: "Investment Portfolio", account_type: "asset"}
]

{:ok, account_positions} = FractionalIndexing.initial_positions(length(account_data))

account_data
|> Enum.zip(account_positions)
|> Enum.each(fn {account_info, position} ->
  %Account{}
  |> Account.create_changeset(%{
    name: account_info.name,
    account_type: account_info.account_type,
    book_id: dummy_book.id,
    position: position
  })
  |> Repo.insert!()
end)

Process.sleep(1)

IO.puts("--------------------------------")
IO.puts("| FINISHED CREATING DUMMY DATA |")
IO.puts("--------------------------------")
