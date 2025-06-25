defmodule PurseCraft.Accounting.Policy do
  @moduledoc false
  use LetMe.Policy

  object :account do
    action :create do
      allow role: :owner
      allow role: :editor
      desc "Create a new Account"
    end
  end
end
