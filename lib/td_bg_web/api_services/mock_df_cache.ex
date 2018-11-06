defmodule TdBg.MockDfCache do
  @moduledoc """
  A mock permissions resolver for simulating Acl and User Redis helpers
  """
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> [] end, name: :MockDfCache)
  end

  def list_templates do
    Agent.get(:MockDfCache, & &1)
  end

  def get_template_by_name(name) do
    :MockDfCache
    |> Agent.get(& &1)
    |> Enum.find(& &1.name == name)
  end

  def put_template(template) do
    Agent.update(:MockDfCache, & [template | &1])
  end

  def clean_cache do
    Agent.update(:MockDfCache, fn _ -> [] end)
  end
end
