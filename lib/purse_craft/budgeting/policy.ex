defmodule PurseCraft.Budgeting.Policy do
  @moduledoc false
  use LetMe.Policy

  object :book do
    action :create do
      allow true
      desc "Create a new Book"
    end

    action :list do
      allow true
      desc "List Books"
    end

    action :read do
      allow [:own_resource, role: :owner]
      allow [:own_resource, role: :editor]
      allow [:own_resource, role: :commenter]
      desc "Read a Book"
    end

    action :update do
      allow [:own_resource, role: :owner]
      desc "Update a Book"
    end

    action :delete do
      allow [:own_resource, role: :owner]
      desc "Delete a Book"
    end
  end

  object :category do
    action :create do
      allow role: :owner
      allow role: :editor
      desc "Create a new Category"
    end

    action :read do
      allow [:own_resource, role: :owner]
      allow [:own_resource, role: :editor]
      allow [:own_resource, role: :commenter]
      desc "Read a Category"
    end

    action :update do
      allow [:own_resource, role: :owner]
      allow [:own_resource, role: :editor]
      desc "Update a Category"
    end

    action :delete do
      allow [:own_resource, role: :owner]
      allow [:own_resource, role: :editor]
      desc "Delete a Category"
    end
  end

  object :envelope do
    action :read do
      allow [:own_resource, role: :owner]
      allow [:own_resource, role: :editor]
      allow [:own_resource, role: :commenter]
      desc "Read an Envelope"
    end
  end
end
