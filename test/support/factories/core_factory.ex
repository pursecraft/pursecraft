defmodule PurseCraft.CoreFactory do
  @moduledoc false

  use PurseCraft.FactoryTemplate

  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Core.Schemas.WorkspaceUser

  def workspace_factory do
    name = Faker.Pokemon.name()

    workspace =
      %Workspace{}
      |> Workspace.changeset(%{name: name})
      |> Ecto.Changeset.apply_changes()

    workspace
  end

  def workspace_user_factory do
    %WorkspaceUser{
      role: Enum.random([:owner, :editor, :commenter])
    }
  end
end
