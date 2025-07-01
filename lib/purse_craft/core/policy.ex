defmodule PurseCraft.Core.Policy do
  @moduledoc false
  use LetMe.Policy

  object :workspace do
    action :create do
      allow true
      desc "Create a new Workspace"
    end

    action :list do
      allow true
      desc "List Workspaces"
    end

    action :read do
      allow [:own_resource, role: :owner]
      allow [:own_resource, role: :editor]
      allow [:own_resource, role: :commenter]
      desc "Read a Workspace"
    end

    action :update do
      allow [:own_resource, role: :owner]
      desc "Update a Workspace"
    end

    action :delete do
      allow [:own_resource, role: :owner]
      desc "Delete a Workspace"
    end
  end
end
