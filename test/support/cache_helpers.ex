defmodule CacheHelpers do
  @moduledoc """
  Support creation of domains in cache
  """

  import ExUnit.Callbacks, only: [on_exit: 1]
  import TdBg.Factory

  alias TdCache.ConceptCache
  alias TdCache.TaxonomyCache
  alias TdCache.TemplateCache

  def insert_template(params \\ %{}) do
    %{id: template_id} = template = build(:template, params)
    {:ok, _} = TemplateCache.put(template, publish: false)
    on_exit(fn -> TemplateCache.delete(template_id) end)
    template
  end

  def insert_domain(params \\ %{}) do
    domain = insert(:domain, params)
    put_domain(domain)
    domain
  end

  def put_domain(%{id: id} = domain) do
    on_exit(fn -> TaxonomyCache.delete_domain(id, clean: true) end)
    TaxonomyCache.put_domain(domain, publish: false)
  end

  def put_concept(%{id: id} = concept) do
    on_exit(fn -> ConceptCache.delete(id) end)
    ConceptCache.put(concept)
  end

  def put_session_permissions(%{} = claims, domain_id, permissions) do
    permissions_by_domain_id = Map.new(permissions, &{to_string(&1), [domain_id]})
    put_session_permissions(claims, permissions_by_domain_id)
  end

  def put_session_permissions(%{jti: session_id, exp: exp}, %{} = permissions_by_domain_id) do
    put_sessions_permissions(session_id, exp, permissions_by_domain_id)
  end

  def put_sessions_permissions(session_id, exp, permissions_by_domain_id) do
    on_exit(fn -> TdCache.Redix.del!("session:#{session_id}:permissions") end)
    TdCache.Permissions.cache_session_permissions!(session_id, exp, permissions_by_domain_id)
  end

  def put_default_permissions(permissions) do
    on_exit(fn -> TdCache.Permissions.put_default_permissions([]) end)
    TdCache.Permissions.put_default_permissions(permissions)
  end
end
