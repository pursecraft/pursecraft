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
      allow role: :owner
      allow role: :editor
      allow role: :commenter
      desc "Read Account details"
    end

    action :update do
      allow role: :owner
      allow role: :editor
      desc "Update Account details"
    end

    action :delete do
      allow role: :owner
      allow role: :editor
      desc "Delete Account"
    end
  end
end
