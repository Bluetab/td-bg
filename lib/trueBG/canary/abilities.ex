defmodule TrueBG.Canary.Abilities do
  @moduledoc false
  alias TrueBG.Accounts.User
  alias TrueBG.Taxonomies.DataDomain
  alias TrueBG.Taxonomies.DomainGroup
  alias TrueBG.BusinessConcepts.BusinessConceptVersion
  alias TrueBG.Canary.TaxonomyAbilities
  alias TrueBG.Canary.BusinessConceptAbilities
  alias TrueBG.Permissions.AclEntry

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

    def can?(%User{} = user, :create_data_domain, %DomainGroup{} = domain_group) do
      TaxonomyAbilities.can?(user, :create_data_domain, domain_group)
    end

    def can?(%User{} = user, :create, %AclEntry{principal_type: "user", resource_type: "domain_group"} = acl_entry) do
      TaxonomyAbilities.can?(user, :create, acl_entry)
    end

    def can?(%User{}, _action, BusinessConceptVersion) do  #when action in [:admin, :watch, :creaBusinte, :publish] do
      true
    end

    def can?(%User{} = user, :update, %BusinessConceptVersion{} = business_concept) do
      BusinessConceptAbilities.can?(user, :update, business_concept)
    end

    def can?(%User{} = user, :send_for_approval, %BusinessConceptVersion{} = business_concept) do
      BusinessConceptAbilities.can?(user, :send_for_approval, business_concept)
    end

    def can?(%User{} = user, :reject, %BusinessConceptVersion{} = business_concept) do
      BusinessConceptAbilities.can?(user, :reject, business_concept)
    end

    def can?(%User{} = user, :publish, %BusinessConceptVersion{} = business_concept) do
      BusinessConceptAbilities.can?(user, :publish, business_concept)
    end

    def can?(%User{}, _action, _domain),  do: false
  end
end
