defmodule PurseCraft.Core.Commands.Workspaces.ChangeWorkspace do
  @moduledoc """
  Returns a changeset for tracking workspace changes.
  """

  alias PurseCraft.Core.Schemas.Workspace

  @type attrs :: %{
          optional(:name) => String.t()
        }

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking workspace changes.

  ## Examples

      iex> call(workspace)
      %Ecto.Changeset{data: %Workspace{}}

      iex> call(workspace, %{name: "New Name"})
      %Ecto.Changeset{data: %Workspace{}, changes: %{name: "New Name"}}

  """
  @spec call(Workspace.t(), attrs()) :: Ecto.Changeset.t()
  def call(%Workspace{} = workspace, attrs \\ %{}) do
    Workspace.changeset(workspace, attrs)
  end
end
