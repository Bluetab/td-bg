defmodule CacheHelpers do
  @moduledoc """
  Support creation of domains in cache
  """

  import TdBg.Factory

  alias TdCache.TaxonomyCache
  alias TdCache.TemplateCache

  def insert_template(params \\ %{}) do
    %{id: template_id} = template = build(:template, params)
    {:ok, _} = TemplateCache.put(template, publish: false)
    ExUnit.Callbacks.on_exit(fn -> TemplateCache.delete(template_id) end)
    template
  end

  def insert_domain(params \\ %{}) do
    %{id: domain_id} = domain = insert(:domain, params)
    TaxonomyCache.put_domain(domain)
    ExUnit.Callbacks.on_exit(fn -> TaxonomyCache.delete_domain(domain_id) end)
    domain
  end
end
