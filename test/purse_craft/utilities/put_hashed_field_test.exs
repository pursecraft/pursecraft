defmodule PurseCraft.Utilities.PutHashedFieldTest do
  use PurseCraft.DataCase, async: true

  import Ecto.Changeset

  alias PurseCraft.Utilities.PutHashedField

  defmodule TestSchema do
    @moduledoc false
    use Ecto.Schema

    schema "test_schemas" do
      field :name, :string
      field :name_hash, :binary
      field :email, :string
      field :email_hash, :binary
      field :description, :string
      field :description_hash, :binary
    end
  end

  describe "call/2 with single field" do
    test "puts hash field when field has value" do
      changeset = cast(%TestSchema{}, %{name: "Test Name"}, [:name])

      result = PutHashedField.call(changeset, :name)

      assert get_field(result, :name_hash) == "Test Name"
    end

    test "does not put hash field when field is nil" do
      changeset = cast(%TestSchema{}, %{}, [:name])

      result = PutHashedField.call(changeset, :name)

      assert get_field(result, :name_hash) == nil
    end

    test "normalizes email to lowercase" do
      changeset = cast(%TestSchema{}, %{email: "Test@Example.COM"}, [:email])

      result = PutHashedField.call(changeset, :email)

      assert get_field(result, :email_hash) == "test@example.com"
    end

    test "handles empty string field when explicitly set" do
      changeset =
        %TestSchema{}
        |> change()
        |> put_change(:name, "")

      result = PutHashedField.call(changeset, :name)

      assert get_field(result, :name_hash) == ""
    end

    test "ignores non-binary field values" do
      changeset =
        %TestSchema{}
        |> change()
        |> put_change(:name, 123)

      result = PutHashedField.call(changeset, :name)

      assert get_field(result, :name_hash) == nil
    end
  end

  describe "call/2 with multiple fields" do
    test "puts hash fields for all specified fields with values" do
      changeset =
        cast(
          %TestSchema{},
          %{
            name: "Test Name",
            email: "Test@Example.COM",
            description: "Test Description"
          },
          [:name, :email, :description]
        )

      result = PutHashedField.call(changeset, [:name, :email, :description])

      assert get_field(result, :name_hash) == "Test Name"
      assert get_field(result, :email_hash) == "test@example.com"
      assert get_field(result, :description_hash) == "Test Description"
    end

    test "skips fields that are nil" do
      changeset =
        cast(
          %TestSchema{},
          %{
            name: "Test Name",
            description: nil
          },
          [:name, :description]
        )

      result = PutHashedField.call(changeset, [:name, :description])

      assert get_field(result, :name_hash) == "Test Name"
      assert get_field(result, :description_hash) == nil
    end

    test "handles empty list of fields" do
      changeset = cast(%TestSchema{}, %{name: "Test Name"}, [:name])

      result = PutHashedField.call(changeset, [])

      assert get_field(result, :name_hash) == nil
    end

    test "handles mixed scenarios with some fields having values" do
      changeset =
        %TestSchema{}
        |> change()
        |> put_change(:name, "Test Name")
        |> put_change(:email, "")
        |> put_change(:description, nil)

      result = PutHashedField.call(changeset, [:name, :email, :description])

      assert get_field(result, :name_hash) == "Test Name"
      assert get_field(result, :email_hash) == ""
      assert get_field(result, :description_hash) == nil
    end
  end

  describe "integration with existing changeset changes" do
    test "preserves existing changes in changeset" do
      changeset =
        %TestSchema{}
        |> change()
        |> put_change(:name, "Original Name")
        |> put_change(:description, "Original Description")

      result = PutHashedField.call(changeset, [:name, :description])

      assert get_field(result, :name) == "Original Name"
      assert get_field(result, :description) == "Original Description"
      assert get_field(result, :name_hash) == "Original Name"
      assert get_field(result, :description_hash) == "Original Description"
    end

    test "overwrites existing hash field values" do
      changeset =
        %TestSchema{}
        |> change()
        |> put_change(:name, "New Name")
        |> put_change(:name_hash, "Old Hash")

      result = PutHashedField.call(changeset, :name)

      assert get_field(result, :name_hash) == "New Name"
    end
  end
end
