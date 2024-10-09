defmodule CacheHelpers do
  @moduledoc """
  Support creation of domains in cache
  """

  import ExUnit.Callbacks, only: [on_exit: 1]
  import TdBg.Factory

  alias TdCache.AclCache
  alias TdCache.ConceptCache
  alias TdCache.HierarchyCache
  alias TdCache.I18nCache
  alias TdCache.ImplementationCache
  alias TdCache.LinkCache
  alias TdCache.RuleCache
  alias TdCache.StructureCache
  alias TdCache.TaxonomyCache
  alias TdCache.TemplateCache
  alias TdCache.UserCache

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

  def insert_rule(%{} = params \\ %{}) do
    rule_id = System.unique_integer([:positive])

    %{id: id} =
      rule =
      params
      |> Map.put_new(:id, rule_id)
      |> Map.put_new(:domain_id, System.unique_integer([:positive]))
      |> Map.put_new(:updated_at, DateTime.utc_now())

    {:ok, _} = RuleCache.put(rule)
    on_exit(fn -> RuleCache.delete_rule(id) end)
    rule
  end

  def delete_implementation(implementation_id) do
    ImplementationCache.delete(implementation_id)
  end

  @spec insert_link(any, any, any, any, any) :: :ok
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

  def put_concept(%{id: id} = concept, concept_version) do
    on_exit(fn -> ConceptCache.delete(id) end)

    concept_entry =
      concept_version
      |> Map.take([:name, :status, :version, :i18n])
      |> Map.merge(concept)

    ConceptCache.put(concept_entry)
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
    on_exit(fn -> TdCache.Redix.del!("session:#{session_id}:domain:permissions") end)

    TdCache.Permissions.cache_session_permissions!(session_id, exp, %{
      "domain" => permissions_by_domain_id
    })
  end

  def put_default_permissions(permissions) do
    on_exit(fn -> TdCache.Permissions.put_default_permissions([]) end)
    TdCache.Permissions.put_default_permissions(permissions)
  end

  def put_i18n_messages(lang, messages) when is_list(messages) do
    Enum.each(messages, &I18nCache.put(lang, &1))
    on_exit(fn -> I18nCache.delete(lang) end)
  end

  def put_i18n_message(lang, message), do: put_i18n_messages(lang, [message])

  def get_business_concept(id) do
    ConceptCache.get(id)
  end

  def put_business_concept(id) do
    ConceptCache.put(id)
    on_exit(fn -> ConceptCache.delete(id) end)
  end

  def insert_user(params \\ %{}) do
    %{id: id} = user = build(:user, params)
    on_exit(fn -> UserCache.delete(id) end)
    {:ok, _} = UserCache.put(user)
    user
  end

  def insert_group(params \\ %{}) do
    %{id: id} = group = build(:group, params)
    on_exit(fn -> UserCache.delete_group(id) end)
    {:ok, _} = UserCache.put_group(group)
    group
  end

  def insert_acl(resource_id, role, user_ids, resource_type \\ "domain") do
    on_exit(fn ->
      AclCache.delete_acl_roles(resource_type, resource_id)
      AclCache.delete_acl_role_users(resource_type, resource_id, role)
    end)

    AclCache.set_acl_roles(resource_type, resource_id, [role])
    AclCache.set_acl_role_users(resource_type, resource_id, role, user_ids)
    :ok
  end

  def insert_group_acl(resource_id, role, group_ids, resource_type \\ "domain") do
    on_exit(fn ->
      AclCache.delete_acl_roles(resource_type, resource_id)
      AclCache.delete_acl_role_groups(resource_type, resource_id, role)
    end)

    AclCache.set_acl_group_roles(resource_type, resource_id, [role])
    AclCache.set_acl_role_groups(resource_type, resource_id, role, group_ids)
    :ok
  end
end
