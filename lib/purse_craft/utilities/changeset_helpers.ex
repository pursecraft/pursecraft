defmodule PurseCraft.Utilities.ChangesetHelpers do
  @moduledoc """
  Helper functions for working with Ecto changesets.
  """

  import Ecto.Changeset

  @doc """
  Copies validation errors from one field to another.

  This is useful when you have encrypted fields with hash counterparts
  where the validation happens on the hash field but you want errors
  to appear on the original field in forms.

  ## Examples

      changeset
      |> unique_constraint(:email_hash)
      |> copy_errors(:email_hash, :email)

  """
  @spec copy_errors(Ecto.Changeset.t(), atom(), atom()) :: Ecto.Changeset.t()
  def copy_errors(changeset, from_field, to_field) do
    case changeset.errors do
      [] ->
        changeset

      _errors ->
        from_errors = Keyword.get_values(changeset.errors, from_field)

        Enum.reduce(from_errors, changeset, fn {message, opts}, acc ->
          add_error(acc, to_field, message, opts)
        end)
    end
  end
end
