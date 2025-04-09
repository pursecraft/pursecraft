defmodule PurseCraft.ContextToFactoryMappings do
  @moduledoc false
  @context_to_factory_mappings %{
    identity: PurseCraft.IdentityFactory
  }

  def factory_for(context) do
    Map.get(@context_to_factory_mappings, context, NotAFactory)
  end
end
