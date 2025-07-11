defmodule PurseCraft.PubSub do
  @moduledoc """
  The PubSub context for handling notifications and broadcasts.
  """

  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub.BroadcastAccount
  alias PurseCraft.PubSub.BroadcastCategory
  alias PurseCraft.PubSub.BroadcastUserWorkspace
  alias PurseCraft.PubSub.BroadcastWorkspace
  alias PurseCraft.PubSub.SubscribeAccount
  alias PurseCraft.PubSub.SubscribeCategory
  alias PurseCraft.PubSub.SubscribeUserWorkspaces
  alias PurseCraft.PubSub.SubscribeWorkspace

  @doc """
  Subscribes to notifications about any workspace changes associated with the scoped user.

  The broadcasted messages match the pattern:

    * {:created, %Workspace{}}
    * {:updated, %Workspace{}}
    * {:deleted, %Workspace{}}

  """
  @spec subscribe_user_workspaces(Scope.t()) :: :ok | {:error, term()}
  defdelegate subscribe_user_workspaces(scope), to: SubscribeUserWorkspaces, as: :call

  @doc """
  Sends notifications about any workspace changes associated with the scoped user.

  The broadcasted messages match the pattern:

    * {:created, %Workspace{}}
    * {:updated, %Workspace{}}
    * {:deleted, %Workspace{}}

  """
  @spec broadcast_user_workspace(Scope.t(), tuple()) :: :ok | {:error, term()}
  defdelegate broadcast_user_workspace(scope, message), to: BroadcastUserWorkspace, as: :call

  @doc """
  Subscribes to notifications about any changes on the given workspace.

  The broadcasted messages match the pattern:

    * {:updated, %Workspace{}}
    * {:deleted, %Workspace{}}

  """
  @spec subscribe_workspace(Workspace.t()) :: :ok | {:error, term()}
  # coveralls-ignore-next-line
  defdelegate subscribe_workspace(workspace), to: SubscribeWorkspace, as: :call

  @doc """
  Sends notifications about any changes on the given workspace

  The broadcasted messages match the pattern:

    * {:updated, %Workspace{}}
    * {:deleted, %Workspace{}}

  """
  @spec broadcast_workspace(Workspace.t(), tuple()) :: :ok | {:error, term()}
  defdelegate broadcast_workspace(workspace, message), to: BroadcastWorkspace, as: :call

  @doc """
  Subscribes to notifications about changes for a specific category.

  The broadcasted messages match the pattern:

    * {:envelope_repositioned, %Envelope{}}
    * {:envelope_removed, %Envelope{}}

  """
  @spec subscribe_category(Ecto.UUID.t()) :: :ok | {:error, term()}
  # coveralls-ignore-next-line
  defdelegate subscribe_category(category_external_id), to: SubscribeCategory, as: :call

  @doc """
  Broadcasts a message to all subscribers of a specific category.

  The broadcasted messages match the pattern:

    * {:envelope_repositioned, envelope}
    * {:envelope_removed, envelope}
    * {:envelope_created, envelope}
    * {:envelope_updated, envelope}
    * {:envelope_deleted, envelope}

  """
  @spec broadcast_category(Category.t(), BroadcastCategory.message()) :: :ok | {:error, term()}
  defdelegate broadcast_category(category, message), to: BroadcastCategory, as: :call

  @doc """
  Subscribes to notifications about changes for a specific account.

  The broadcasted messages match the pattern:

    * {:created, %Account{}}
    * {:updated, %Account{}}
    * {:deleted, %Account{}}
    * {:closed, %Account{}}
    * {:repositioned, %Account{}}

  """
  @spec subscribe_account(Account.t()) :: :ok | {:error, term()}
  defdelegate subscribe_account(account), to: SubscribeAccount, as: :call

  @doc """
  Broadcasts a message to all subscribers of a specific account.

  The broadcasted messages match the pattern:

    * {:created, %Account{}}
    * {:updated, %Account{}}
    * {:deleted, %Account{}}
    * {:closed, %Account{}}
    * {:repositioned, %Account{}}

  """
  @spec broadcast_account(Account.t(), BroadcastAccount.message()) :: :ok | {:error, term()}
  defdelegate broadcast_account(account, message), to: BroadcastAccount, as: :call
end
