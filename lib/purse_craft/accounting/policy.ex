defmodule PurseCraft.Accounting.Policy do
  @moduledoc false
  use LetMe.Policy

  object :account do
    action :create do
      allow role: :owner
      allow role: :editor
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

  object :payee do
    action :create do
      allow role: :owner
      allow role: :editor
      desc "Create a new Payee"
    end

    action :read do
      allow [:own_resource, role: :owner]
      allow [:own_resource, role: :editor]
      allow [:own_resource, role: :commenter]
      desc "Read a Payee"
    end

    action :update do
      allow [:own_resource, role: :owner]
      allow [:own_resource, role: :editor]
      desc "Update a Payee"
    end

    action :delete do
      allow [:own_resource, role: :owner]
      allow [:own_resource, role: :editor]
      desc "Delete a Payee"
    end
  end
end
