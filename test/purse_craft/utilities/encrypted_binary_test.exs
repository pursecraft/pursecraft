defmodule PurseCraft.Utilities.EncryptedBinaryTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity

  describe "email encryption" do
    test "encrypts and decrypts email properly" do
      email = "test@example.com"

      # Register a user with email encryption
      {:ok, user} = Identity.register_user(%{email: email})

      # Verify the email is stored encrypted and decrypts correctly
      assert user.email == email
      assert user.email_hash == String.downcase(email)

      # Verify we can retrieve the user by email
      retrieved_user = Identity.get_user_by_email(email)
      assert retrieved_user.id == user.id
      assert retrieved_user.email == email
    end

    test "handles case-insensitive email lookup" do
      email = "Test@Example.COM"

      # Register a user with mixed case email
      {:ok, user} = Identity.register_user(%{email: email})

      # Verify we can retrieve with different case
      retrieved_user = Identity.get_user_by_email("test@example.com")
      assert retrieved_user.id == user.id
      assert retrieved_user.email == email

      # Verify we can retrieve with original case
      retrieved_user2 = Identity.get_user_by_email(email)
      assert retrieved_user2.id == user.id
    end

    test "prevents duplicate emails with different cases" do
      # Create first user
      {:ok, _user} = Identity.register_user(%{email: "test@example.com"})

      # Try to create another user with different case
      {:error, changeset} = Identity.register_user(%{email: "TEST@EXAMPLE.COM"})

      assert "has already been taken" in errors_on(changeset).email_hash
    end
  end
end
