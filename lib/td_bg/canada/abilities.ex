defmodule TdBg.Canada.Abilities do
  @moduledoc false

  alias TdBg.Auth.Claims
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Canada.BusinessConceptAbilities
  alias TdBg.Canada.LinkAbilities
  alias TdBg.Canada.TaxonomyAbilities
  alias TdBg.Taxonomies.Domain
  alias TdCache.Link

  defimpl Canada.Can, for: Claims do
    # administrator can manage all domains and concepts
    def can?(%Claims{role: "admin"}, _action, BusinessConcept), do: true
    def can?(%Claims{role: "admin"}, _action, %BusinessConcept{}), do: true
    def can?(%Claims{role: "admin"}, _action, Domain), do: true
    def can?(%Claims{role: "admin"}, _action, %Domain{}), do: true

    def can?(%Claims{} = claims, action, %Link{} = link) do
      LinkAbilities.can?(claims, action, link)
    end

    def can?(%Claims{} = claims, :create_concept_link, %{business_concept: business_concept}) do
      LinkAbilities.can?(claims, :create_concept_link, business_concept)
    end

    def can?(%Claims{} = claims, :create_structure_link, %{business_concept: business_concept}) do
      LinkAbilities.can?(claims, :create_structure_link, business_concept)
    end

    def can?(%Claims{} = claims, action, %{hint: :link} = resource) do
      LinkAbilities.can?(claims, action, resource)
    end

    def can?(%Claims{} = claims, :create_business_concept, %Domain{} = domain) do
      BusinessConceptAbilities.can?(claims, :create_business_concept, domain)
    end

    def can?(%Claims{} = claims, :update_business_concept, %Domain{} = domain) do
      BusinessConceptAbilities.can?(claims, :update_business_concept, domain)
    end

    def can?(%Claims{} = claims, :create_ingest, %Domain{} = domain) do
      BusinessConceptAbilities.can?(claims, :create_ingest, domain)
    end

    def can?(%Claims{} = claims, :list, Domain) do
      TaxonomyAbilities.can?(claims, :list, Domain)
    end

    def can?(%Claims{} = claims, permission, %Domain{} = domain) do
      TaxonomyAbilities.can?(claims, permission, domain)
    end

    def can?(%Claims{} = claims, :create, BusinessConceptVersion) do
      BusinessConceptAbilities.can?(claims, :create_business_concept)
    end

    def can?(%Claims{} = claims, :upload, BusinessConceptVersion) do
      BusinessConceptAbilities.can?(claims, :create_business_concept)
    end

    def can?(%Claims{} = claims, :upload, BusinessConcept) do
      BusinessConceptAbilities.can?(claims, :create_business_concept)
    end

    def can?(%Claims{} = claims, :share_with_domain, %BusinessConcept{} = business_concept) do
      BusinessConceptAbilities.can?(claims, :share_with_domain, business_concept)
    end

    def can?(%Claims{} = claims, :upload, %Domain{} = domain) do
      BusinessConceptAbilities.can?(claims, :create_business_concept, domain)
    end

    def can?(%Claims{} = claims, :update, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(claims, :update, business_concept_version)
    end

    def can?(%Claims{} = claims, :update, %BusinessConcept{} = business_concept) do
      BusinessConceptAbilities.can?(claims, :update, business_concept)
    end

    def can?(
          %Claims{} = claims,
          :get_data_structures,
          %BusinessConceptVersion{} = business_concept_version
        ) do
      BusinessConceptAbilities.can?(claims, :get_data_structures, business_concept_version)
    end

    def can?(
          %Claims{} = claims,
          :send_for_approval,
          %BusinessConceptVersion{} = business_concept_version
        ) do
      BusinessConceptAbilities.can?(claims, :send_for_approval, business_concept_version)
    end

    def can?(%Claims{} = claims, :reject, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(claims, :reject, business_concept_version)
    end

    def can?(
          %Claims{} = claims,
          :undo_rejection,
          %BusinessConceptVersion{} = business_concept_version
        ) do
      BusinessConceptAbilities.can?(claims, :undo_rejection, business_concept_version)
    end

    def can?(%Claims{} = claims, :publish, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(claims, :publish, business_concept_version)
    end

    def can?(%Claims{} = claims, :version, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(claims, :version, business_concept_version)
    end

    def can?(
          %Claims{} = claims,
          :deprecate,
          %BusinessConceptVersion{} = business_concept_version
        ) do
      BusinessConceptAbilities.can?(claims, :deprecate, business_concept_version)
    end

    def can?(%Claims{} = claims, :delete, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(claims, :delete, business_concept_version)
    end

    def can?(
          %Claims{} = claims,
          :set_confidential,
          %BusinessConceptVersion{} = business_concept_version
        ) do
      BusinessConceptAbilities.can?(
        claims,
        :manage_confidential_business_concepts,
        business_concept_version
      )
    end

    def can?(
          %Claims{} = claims,
          :view_business_concept,
          %BusinessConceptVersion{} = business_concept_version
        ) do
      BusinessConceptAbilities.can?(claims, :view_business_concept, business_concept_version)
    end

    def can?(%Claims{role: "admin"}, _action, %{}), do: true
    def can?(%Claims{}, _action, _domain), do: false
  end
end
