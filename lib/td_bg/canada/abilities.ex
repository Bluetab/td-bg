defmodule TdBg.Canada.Abilities do
  @moduledoc false

  alias TdBg.Accounts.User
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Canada.BusinessConceptAbilities
  alias TdBg.Canada.LinkAbilities
  alias TdBg.Canada.TaxonomyAbilities
  alias TdBg.Taxonomies.Domain
  alias TdCache.Link

  defimpl Canada.Can, for: User do
    # administrator is superpowerful for Domain
    def can?(%User{is_admin: true}, _action, BusinessConcept) do
      true
    end

    def can?(%User{is_admin: true}, _action, %BusinessConcept{}) do
      true
    end

    def can?(%User{is_admin: true}, _action, Domain) do
      true
    end

    def can?(%User{is_admin: true}, _action, %Domain{}) do
      true
    end

    def can?(%User{} = user, action, %Link{} = link) do
      LinkAbilities.can?(user, action, link)
    end

    def can?(%User{} = user, :create_link, %{business_concept: business_concept}) do
      LinkAbilities.can?(user, :create_link, business_concept)
    end

    def can?(%User{} = user, action, %{hint: :link} = resource) do
      LinkAbilities.can?(user, action, resource)
    end

    def can?(%User{} = user, :list, Domain) do
      TaxonomyAbilities.can?(user, :list, Domain)
    end

    def can?(%User{} = user, :create, %Domain{} = domain) do
      TaxonomyAbilities.can?(user, :create, domain)
    end

    def can?(%User{} = user, :update, %Domain{} = domain) do
      TaxonomyAbilities.can?(user, :update, domain)
    end

    def can?(%User{} = user, :show, %Domain{} = domain) do
      TaxonomyAbilities.can?(user, :show, domain)
    end

    def can?(%User{} = user, :delete, %Domain{} = domain) do
      TaxonomyAbilities.can?(user, :delete, domain)
    end

    def can?(%User{} = user, :create_business_concept, %Domain{} = domain) do
      BusinessConceptAbilities.can?(user, :create_business_concept, domain)
    end

    def can?(%User{} = user, :create_ingest, %Domain{} = domain) do
      BusinessConceptAbilities.can?(user, :create_ingest, domain)
    end

    def can?(%User{} = user, :create, BusinessConceptVersion) do
      BusinessConceptAbilities.can?(user, :create_business_concept)
    end

    def can?(%User{} = user, :update, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(user, :update, business_concept_version)
    end

    def can?(
          %User{} = user,
          :get_data_structures,
          %BusinessConceptVersion{} = business_concept_version
        ) do
      BusinessConceptAbilities.can?(user, :get_data_structures, business_concept_version)
    end

    def can?(
          %User{} = user,
          :send_for_approval,
          %BusinessConceptVersion{} = business_concept_version
        ) do
      BusinessConceptAbilities.can?(user, :send_for_approval, business_concept_version)
    end

    def can?(%User{} = user, :reject, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(user, :reject, business_concept_version)
    end

    def can?(
          %User{} = user,
          :undo_rejection,
          %BusinessConceptVersion{} = business_concept_version
        ) do
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

    def can?(
          %User{} = user,
          :view_business_concept,
          %BusinessConceptVersion{} = business_concept_version
        ) do
      BusinessConceptAbilities.can?(user, :view_business_concept, business_concept_version)
    end

    def can?(%User{} = user, permission, %{hint: :business_concept_versions} = resource) do
      can?(user, permission, BusinessConceptVersion.to_struct(Map.delete(resource, :hint)))
    end

    def can?(%User{} = user, permission, %{hint: :domains} = resource) do
      can?(user, permission, Domain.to_struct(Map.delete(resource, :hint)))
    end

    def can?(%User{is_admin: true}, _action, BusinessConceptVersion), do: true

    def can?(%User{is_admin: true}, _action, %BusinessConceptVersion{}), do: true

    def can?(%User{is_admin: true}, _action, %{}), do: true

    def can?(%User{}, _action, _domain), do: false
  end
end
