defmodule TdBg.Canary.Abilities do
  @moduledoc false
  alias TdBg.Accounts.User
  alias TdBg.Taxonomies.DataDomain
  alias TdBg.Taxonomies.DomainGroup
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Canary.TaxonomyAbilities
  alias TdBg.Canary.BusinessConceptAbilities
  alias TdBg.Permissions.AclEntry

  defimpl Canada.Can, for: User do

    #def can?(%User{}, _action, nil),  do: false

    # administrator is superpowerful
    def can?(%User{is_admin: true}, _action, _domain)  do
      true
    end
    # Data domain

    # This is the creation of a business concept in a data domain
    def can?(%User{} = user, :create_business_concept, %DataDomain{} = data_domain)  do
      BusinessConceptAbilities.can?(user, :create_business_concept, data_domain)
    end

    def can?(%User{} = user, :update, %DataDomain{} = data_domain) do
      TaxonomyAbilities.can?(user, :update, data_domain)
    end

    def can?(%User{} = user, :delete, %DataDomain{} = data_domain) do
      TaxonomyAbilities.can?(user, :delete, data_domain)
    end

    def can?(%User{} = user, :create_data_domain, %DomainGroup{} = domain_group) do
      TaxonomyAbilities.can?(user, :create_data_domain, domain_group)
    end

    def can?(%User{} = user, :create, %DomainGroup{} = domain_group) do
      TaxonomyAbilities.can?(user, :create, domain_group)
    end

    def can?(%User{} = user, :update, %DomainGroup{} = domain_group) do
      TaxonomyAbilities.can?(user, :update, domain_group)
    end

    def can?(%User{} = user, :delete, %DomainGroup{} = domain_group) do
      TaxonomyAbilities.can?(user, :delete, domain_group)
    end

    def can?(%User{} = user, :create, %AclEntry{principal_type: "user", resource_type: "domain_group"} = acl_entry) do
      TaxonomyAbilities.can?(user, :create, acl_entry)
    end

    def can?(%User{} = user, :create, %AclEntry{principal_type: "user", resource_type: "data_domain"} = acl_entry) do
      TaxonomyAbilities.can?(user, :create, acl_entry)
    end

    def can?(%User{}, _action, BusinessConceptVersion) do  #when action in [:admin, :watch, :creaBusinte, :publish] do
      true
    end

    def can?(%User{} = user, :update, %BusinessConceptVersion{} = business_concept_vesion) do
      BusinessConceptAbilities.can?(user, :update, business_concept_vesion)
    end

    def can?(%User{} = user, :send_for_approval, %BusinessConceptVersion{} = business_concept_vesion) do
      BusinessConceptAbilities.can?(user, :send_for_approval, business_concept_vesion)
    end

    def can?(%User{} = user, :reject, %BusinessConceptVersion{} = business_concept_vesion) do
      BusinessConceptAbilities.can?(user, :reject, business_concept_vesion)
    end

    def can?(%User{} = user, :publish, %BusinessConceptVersion{} = business_concept_vesion) do
      BusinessConceptAbilities.can?(user, :publish, business_concept_vesion)
    end

    def can?(%User{} = user, :deprecate, %BusinessConceptVersion{} = business_concept_vesion) do
      BusinessConceptAbilities.can?(user, :deprecate, business_concept_vesion)
    end

    def can?(%User{} = user, :update_published, %BusinessConceptVersion{} = business_concept_vesion) do
      BusinessConceptAbilities.can?(user, :update_published, business_concept_vesion)
    end

    def can?(%User{} = user, :delete, %BusinessConceptVersion{} = business_concept_vesion) do
      BusinessConceptAbilities.can?(user, :delete, business_concept_vesion)
    end

    def can?(%User{} = user, :view_versions, %BusinessConceptVersion{} = business_concept_vesion) do
      BusinessConceptAbilities.can?(user, :view_versions, business_concept_vesion)
    end

    def can?(%User{}, _action, _domain),  do: false
  end
end
