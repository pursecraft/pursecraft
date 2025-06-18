defmodule PurseCraft.Accounting.Policy do
  @moduledoc false
  use LetMe.Policy

  object :account do
    action :create do
      allow [:own_resource, role: :owner]
      allow [:own_resource, role: :editor]
      desc "Create a new Account"
    end

    action :read do
      allow [:own_resource, role: :owner]
      allow [:own_resource, role: :editor]
      allow [:own_resource, role: :commenter]
      desc "Read an Account"
    end

    action :update do
      allow [:own_resource, role: :owner]
      allow [:own_resource, role: :editor]
      desc "Update an Account"
    end

    action :delete do
      allow [:own_resource, role: :owner]
      allow [:own_resource, role: :editor]
      desc "Delete an Account"
    end
  end
end
