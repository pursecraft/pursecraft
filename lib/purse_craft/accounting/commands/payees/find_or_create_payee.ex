defmodule PurseCraft.Accounting.Commands.Payees.FindOrCreatePayee do
  @moduledoc """
  Finds an existing payee by name within a workspace or creates a new one if not found.
  """

  alias PurseCraft.Accounting.Commands.Payees.CreatePayee
  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.PayeeRepository
  alias PurseCraft.Accounting.Schemas.Payee
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope

  @doc """
  Finds an existing payee by name within a workspace or creates a new one if not found.

  ## Examples

      iex> FindOrCreatePayee.call(authorized_scope, workspace, "Grocery Store")
      {:ok, %Payee{}}

      iex> FindOrCreatePayee.call(authorized_scope, workspace, "  New Store  ")
      {:ok, %Payee{name: "New Store"}}

      iex> FindOrCreatePayee.call(authorized_scope, workspace, "")
      {:error, :invalid_payee_name}

      iex> FindOrCreatePayee.call(unauthorized_scope, workspace, "Grocery Store")
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Workspace.t(), String.t()) ::
          {:ok, Payee.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized} | {:error, :invalid_payee_name}
  def call(%Scope{} = scope, %Workspace{} = workspace, payee_name) do
    with {:ok, trimmed_name} <- validate_payee_name(payee_name),
         :ok <- Policy.authorize(:payee_create, scope, %{workspace: workspace}) do
      case PayeeRepository.get_by_name(workspace, trimmed_name) do
        nil -> CreatePayee.call(scope, workspace, %{name: trimmed_name})
        payee -> {:ok, payee}
      end
    end
  end

  defp validate_payee_name(name) when is_binary(name) do
    case String.trim(name) do
      "" -> {:error, :invalid_payee_name}
      trimmed_name -> {:ok, trimmed_name}
    end
  end

  defp validate_payee_name(_invalid_input), do: {:error, :invalid_payee_name}
end
