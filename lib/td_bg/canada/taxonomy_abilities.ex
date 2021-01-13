defmodule TdBg.Canada.TaxonomyAbilities do
  @moduledoc false
  alias TdBg.Auth.Session
  alias TdBg.Permissions
  alias TdBg.Taxonomies.Domain

  def can?(%Session{} = session, :list, Domain) do
    permissions = [
      :create_domain,
      :update_domain,
      :delete_domain,
      :create_acl_entry,
      :update_acl_entry,
      :delete_acl_entry,
      :view_domain
    ]

    Permissions.has_any_permission_on_resource_type?(session, permissions, Domain)
  end

  def can?(%Session{} = session, :create, %Domain{id: domain_id}) do
    Permissions.authorized?(session, :create_domain, domain_id)
  end

  def can?(%Session{} = session, :update, %Domain{id: domain_id}) do
    Permissions.authorized?(session, :update_domain, domain_id)
  end

  def can?(%Session{} = session, :show, %Domain{id: domain_id}) do
    Permissions.authorized?(session, :view_domain, domain_id)
  end

  def can?(%Session{} = session, :delete, %Domain{id: domain_id}) do
    Permissions.authorized?(session, :delete_domain, domain_id)
  end

  def can?(%Session{} = session, :delete_link, %Domain{id: domain_id}) do
    Permissions.authorized?(session, :manage_business_concept_links, domain_id)
  end

  def can?(%Session{} = session, :create_link, %Domain{id: domain_id}) do
    Permissions.authorized?(session, :manage_business_concept_links, domain_id)
  end

  def can?(%Session{} = session, :move, %Domain{} = domain) do
    can?(session, :delete, domain) and can?(session, :update, domain)
  end

  def can?(%Session{} = session, :manage_data_sources, %Domain{id: domain_id}) do
    Permissions.authorized?(session, :manage_data_sources, domain_id)
  end

  def can?(%Session{} = session, :manage_configurations, %Domain{id: domain_id}) do
    Permissions.authorized?(session, :manage_configurations, domain_id)
  end

  def can?(%Session{} = session, :update_data_structure, %Domain{id: domain_id}) do
    Permissions.authorized?(session, :update_data_structure, domain_id)
  end

  def can?(%Session{} = session, :manage_quality_rule, %Domain{id: domain_id}) do
    Permissions.authorized?(session, :manage_quality_rule, domain_id)
  end

  def can?(%Session{} = session, :update_ingest, %Domain{id: domain_id}) do
    Permissions.authorized?(session, :update_ingest, domain_id)
  end
end
