defmodule TdBg.Canada.TaxonomyAbilities do
  @moduledoc false
  alias TdBg.Auth.Claims
  alias TdBg.Permissions
  alias TdBg.Taxonomies.Domain

  # Service account can view all domains
  def can?(%Claims{role: "service"}, :show, %Domain{}), do: true

  def can?(%Claims{} = claims, :list, Domain) do
    permissions = [
      :create_domain,
      :update_domain,
      :delete_domain,
      :create_acl_entry,
      :update_acl_entry,
      :delete_acl_entry,
      :view_domain
    ]

    Permissions.has_any_permission_on_resource_type?(claims, permissions, Domain)
  end

  def can?(%Claims{} = claims, :create, %Domain{id: domain_id}) do
    Permissions.authorized?(claims, :create_domain, domain_id)
  end

  def can?(%Claims{} = claims, :update, %Domain{id: domain_id}) do
    Permissions.authorized?(claims, :update_domain, domain_id)
  end

  def can?(%Claims{} = claims, :show, %Domain{id: domain_id}) do
    Permissions.authorized?(claims, :view_domain, domain_id)
  end

  def can?(%Claims{} = claims, :delete, %Domain{id: domain_id}) do
    Permissions.authorized?(claims, :delete_domain, domain_id)
  end

  def can?(%Claims{} = claims, :delete_link, %Domain{id: domain_id}) do
    Permissions.authorized?(claims, :manage_business_concept_links, domain_id)
  end

  def can?(%Claims{} = claims, :create_concept_link, %Domain{id: domain_id}) do
    Permissions.authorized?(claims, :manage_business_concept_links, domain_id)
  end

  def can?(%Claims{} = claims, :create_structure_link, %Domain{id: domain_id}) do
    Permissions.authorized?(claims, :manage_business_concept_links, domain_id)
  end

  def can?(%Claims{} = claims, :manage_structures_domain, %Domain{id: domain_id}) do
    Permissions.authorized?(claims, :manage_structures_domain, domain_id)
  end

  def can?(%Claims{} = claims, :move, %Domain{} = domain) do
    can?(claims, :delete, domain) and can?(claims, :update, domain)
  end

  def can?(%Claims{} = claims, :manage_data_sources, %Domain{id: domain_id}) do
    Permissions.authorized?(claims, :manage_data_sources, domain_id)
  end

  def can?(%Claims{} = claims, :manage_configurations, %Domain{id: domain_id}) do
    Permissions.authorized?(claims, :manage_configurations, domain_id)
  end

  def can?(%Claims{} = claims, :update_data_structure, %Domain{id: domain_id}) do
    Permissions.authorized?(claims, :update_data_structure, domain_id)
  end

  def can?(%Claims{} = claims, :manage_quality_rule, %Domain{id: domain_id}) do
    Permissions.authorized?(claims, :manage_quality_rule, domain_id)
  end

  def can?(%Claims{} = claims, :update_ingest, %Domain{id: domain_id}) do
    Permissions.authorized?(claims, :update_ingest, domain_id)
  end

  def can?(%Claims{} = claims, :view_dashboard, %Domain{id: domain_id}) do
    Permissions.authorized?(claims, :view_dashboard, domain_id)
  end

  def can?(%Claims{} = claims, :view_quality_rule, %Domain{id: domain_id}) do
    Permissions.authorized?(claims, :view_quality_rule, domain_id)
  end
end
