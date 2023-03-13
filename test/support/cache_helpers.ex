defmodule CacheHelpers do
  @moduledoc """
  Support creation of domains in cache
  """

  import ExUnit.Callbacks, only: [on_exit: 1]
  import TdBg.Factory

  alias TdCache.ConceptCache
  alias TdCache.HierarchyCache
  alias TdCache.ImplementationCache
  alias TdCache.LinkCache
  alias TdCache.StructureCache
  alias TdCache.TaxonomyCache
  alias TdCache.TemplateCache

  def insert_template(params \\ %{}) do
    %{id: template_id} = template = build(:template, params)
    {:ok, _} = TemplateCache.put(template, publish: false)
    on_exit(fn -> TemplateCache.delete(template_id) end)
    template
  end

  def insert_hierarchy(params) do
    %{id: hierarchy_id} = hierarchy = build(:hierarchy, params)
    {:ok, _} = HierarchyCache.put(hierarchy, publish: false)
    on_exit(fn -> HierarchyCache.delete(hierarchy_id) end)
    hierarchy
  end

  def insert_domain(params \\ %{}) do
    domain = insert(:domain, params)
    put_domain(domain)
    domain
  end

  def insert_data_structure(%{} = params \\ %{}) do
    %{id: id} =
      data_structure =
      params
      |> Map.put_new(:id, System.unique_integer([:positive]))
      |> Map.put_new(:name, "linked data_structure name")
      |> Map.put_new(:updated_at, DateTime.utc_now())

    {:ok, _} = StructureCache.put(data_structure, publish: false)
    on_exit(fn -> StructureCache.delete(id) end)
    data_structure
  end

  def insert_implementation(%{} = params \\ %{}) do
    impl_id = System.unique_integer([:positive])

    %{id: id} =
      implementation =
      params
      |> Map.put_new(:id, impl_id)
      |> Map.put_new(:implementation_ref, impl_id)
      |> Map.put_new(:domain_id, System.unique_integer([:positive]))
      |> Map.put_new(:implementation_key, "imple_key_#{impl_id}")
      |> Map.put_new(:updated_at, DateTime.utc_now())

    {:ok, _} = ImplementationCache.put(implementation, publish: false)
    on_exit(fn -> ImplementationCache.delete(id) end)
    implementation
  end

  def delete_implementation(implementation_id) do
    ImplementationCache.delete(implementation_id)
  end

  def insert_link(source_id, source_type, target_type, target_id, tags \\ []) do
    id = System.unique_integer([:positive])
    target_id = if is_nil(target_id), do: System.unique_integer([:positive]), else: target_id

    LinkCache.put(
      %{
        id: id,
        source_type: source_type,
        source_id: source_id,
        target_type: target_type,
        target_id: target_id,
        tags: List.wrap(tags),
        updated_at: DateTime.utc_now()
      },
      publish: false
    )

    on_exit(fn -> LinkCache.delete(id, publish: false) end)
    :ok
  end

  def put_domain(%{id: id} = domain) do
    on_exit(fn -> TaxonomyCache.delete_domain(id, clean: true) end)
    {:ok, _} = TaxonomyCache.put_domain(domain)
  end

  def put_concept(%{id: id} = concept) do
    on_exit(fn -> ConceptCache.delete(id) end)
    ConceptCache.put(concept)
  end

  def put_implementation(%{id: id} = implementation) do
    on_exit(fn -> ImplementationCache.delete(id) end)
    ImplementationCache.put(implementation)
  end

  def put_session_permissions(%{jti: session_id, exp: exp}, %{} = permissions_by_domain_id) do
    put_session_permissions(session_id, exp, permissions_by_domain_id)
  end

  def put_session_permissions(%{} = claims, domain_id, permissions) do
    permissions_by_domain_id = Map.new(permissions, &{to_string(&1), [domain_id]})
    put_session_permissions(claims, permissions_by_domain_id)
  end

  def put_session_permissions(session_id, exp, permissions_by_domain_id) do
    on_exit(fn -> TdCache.Redix.del!("session:#{session_id}:permissions") end)
    TdCache.Permissions.cache_session_permissions!(session_id, exp, permissions_by_domain_id)
  end

  def put_default_permissions(permissions) do
    on_exit(fn -> TdCache.Permissions.put_default_permissions([]) end)
    TdCache.Permissions.put_default_permissions(permissions)
  end
end
