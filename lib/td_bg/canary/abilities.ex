defmodule TdBg.Canary.Abilities do
  @moduledoc false
  alias TdBg.Accounts.User
  alias TdBg.Taxonomies.Domain
  alias TdBg.Permissions.Role
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Canary.TaxonomyAbilities
  alias TdBg.Canary.BusinessConceptAbilities
  alias TdBg.Permissions.AclEntry

  defimpl Canada.Can, for: User do

    #def can?(%User{}, _action, nil), do: false

    # administrator is superpowerful for Domain, Role and AclEntry
    def can?(%User{is_admin: true}, _action, Domain) do
      true
    end

    def can?(%User{is_admin: true}, _action, %Domain{}) do
      true
    end

    def can?(%User{is_admin: true}, _action, Role) do
      true
    end

    def can?(%User{is_admin: true}, _action, %Role{}) do
      true
    end

    def can?(%User{is_admin: true}, _action, %AclEntry{}) do
      true
    end

    def can?(%User{} = user, :list, Domain) do
      TaxonomyAbilities.can?(user, :list, Domain)
    end

    def can?(%User{} = user, :create, Domain) do
      TaxonomyAbilities.can?(user, :create, Domain)
    end

    def can?(%User{} = user, :create, %Domain{} = domain) do
      TaxonomyAbilities.can?(user, :create, domain)
    end

    def can?(%User{} = user, :update, %Domain{} = domain) do
      TaxonomyAbilities.can?(user, :update, domain)
    end

    def can?(%User{} = user, :delete, %Domain{} = domain) do
      TaxonomyAbilities.can?(user, :delete, domain)
    end

    def can?(%User{} = user, :create, %AclEntry{principal_type: "user", resource_type: "domain"} = acl_entry) do
      TaxonomyAbilities.can?(user, :create, acl_entry)
    end

    def can?(%User{} = user, :create_business_concept, %Domain{} = domain) do
      BusinessConceptAbilities.can?(user, :create_business_concept, domain)
    end

    def can?(%User{} = user, :update, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(user, :update, business_concept_version)
    end

    def can?(%User{} = user, :send_for_approval, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(user, :send_for_approval, business_concept_version)
    end

    def can?(%User{} = user, :reject, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(user, :reject, business_concept_version)
    end

    def can?(%User{} = user, :undo_rejection, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(user, :undo_rejection, business_concept_version)
    end

    def can?(%User{} = user, :publish, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(user, :publish, business_concept_version)
    end

    def can?(%User{} = user, :version, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(user, :version, business_concept_version)
    end

    def can?(%User{} = user, :deprecate, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(user, :deprecate, business_concept_version)
    end

    def can?(%User{} = user, :delete, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(user, :delete, business_concept_version)
    end

    def can?(%User{} = user, :view_versions, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(user, :view_versions, business_concept_version)
    end

    def can?(%User{} = user, :view_business_concept, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(user, :view_business_concept, business_concept_version)
    end

    def can?(%User{} = user, :create_alias, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(user, :manage_alias, business_concept_version)
    end

    def can?(%User{} = user, :delete_alias, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(user, :manage_alias, business_concept_version)
    end

    # TODO: Controlar hypermedia collections?
    def can?(%User{is_admin: true}, _action, %{}) do
      true
    end

    def can?(%User{}, _action, _domain), do: false
  end
end
