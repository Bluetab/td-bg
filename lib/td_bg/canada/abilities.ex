defmodule TdBg.Canada.Abilities do
  @moduledoc false

  alias TdBg.Accounts.Session
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Canada.BusinessConceptAbilities
  alias TdBg.Canada.LinkAbilities
  alias TdBg.Canada.TaxonomyAbilities
  alias TdBg.Taxonomies.Domain
  alias TdCache.Link

  defimpl Canada.Can, for: Session do
    # administrator is superpowerful for Domain
    def can?(%Session{is_admin: true}, _action, BusinessConcept) do
      true
    end

    def can?(%Session{is_admin: true}, _action, %BusinessConcept{}) do
      true
    end

    def can?(%Session{is_admin: true}, _action, Domain) do
      true
    end

    def can?(%Session{is_admin: true}, _action, %Domain{}) do
      true
    end

    def can?(%Session{} = session, action, %Link{} = link) do
      LinkAbilities.can?(session, action, link)
    end

    def can?(%Session{} = session, :create_link, %{business_concept: business_concept}) do
      LinkAbilities.can?(session, :create_link, business_concept)
    end

    def can?(%Session{} = session, action, %{hint: :link} = resource) do
      LinkAbilities.can?(session, action, resource)
    end

    def can?(%Session{} = session, :list, Domain) do
      TaxonomyAbilities.can?(session, :list, Domain)
    end

    def can?(%Session{} = session, :create, %Domain{} = domain) do
      TaxonomyAbilities.can?(session, :create, domain)
    end

    def can?(%Session{} = session, :update, %Domain{} = domain) do
      TaxonomyAbilities.can?(session, :update, domain)
    end

    def can?(%Session{} = session, :show, %Domain{} = domain) do
      TaxonomyAbilities.can?(session, :show, domain)
    end

    def can?(%Session{} = session, :delete, %Domain{} = domain) do
      TaxonomyAbilities.can?(session, :delete, domain)
    end

    def can?(%Session{} = session, :move, %Domain{} = domain) do
      TaxonomyAbilities.can?(session, :move, domain)
    end

    def can?(%Session{} = session, :create_business_concept, %Domain{} = domain) do
      BusinessConceptAbilities.can?(session, :create_business_concept, domain)
    end

    def can?(%Session{} = session, :update_business_concept, %Domain{} = domain) do
      BusinessConceptAbilities.can?(session, :update_business_concept, domain)
    end

    def can?(%Session{} = session, :create_ingest, %Domain{} = domain) do
      BusinessConceptAbilities.can?(session, :create_ingest, domain)
    end

    def can?(%Session{} = session, :manage_data_sources, %Domain{} = domain) do
      TaxonomyAbilities.can?(session, :manage_data_sources, domain)
    end

    def can?(%Session{} = session, :manage_configurations, %Domain{} = domain) do
      TaxonomyAbilities.can?(session, :manage_configurations, domain)
    end

    def can?(%Session{} = session, :update_data_structure, %Domain{} = domain) do
      TaxonomyAbilities.can?(session, :update_data_structure, domain)
    end

    def can?(%Session{} = session, :manage_quality_rule, %Domain{} = domain) do
      TaxonomyAbilities.can?(session, :manage_quality_rule, domain)
    end

    def can?(%Session{} = session, :update_ingest, %Domain{} = domain) do
      TaxonomyAbilities.can?(session, :update_ingest, domain)
    end

    def can?(%Session{} = session, :create, BusinessConceptVersion) do
      BusinessConceptAbilities.can?(session, :create_business_concept)
    end

    def can?(%Session{} = session, :update, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(session, :update, business_concept_version)
    end

    def can?(%Session{} = session, :update, %BusinessConcept{} = business_concept) do
      BusinessConceptAbilities.can?(session, :update, business_concept)
    end

    def can?(
          %Session{} = session,
          :get_data_structures,
          %BusinessConceptVersion{} = business_concept_version
        ) do
      BusinessConceptAbilities.can?(session, :get_data_structures, business_concept_version)
    end

    def can?(
          %Session{} = session,
          :send_for_approval,
          %BusinessConceptVersion{} = business_concept_version
        ) do
      BusinessConceptAbilities.can?(session, :send_for_approval, business_concept_version)
    end

    def can?(%Session{} = session, :reject, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(session, :reject, business_concept_version)
    end

    def can?(
          %Session{} = session,
          :undo_rejection,
          %BusinessConceptVersion{} = business_concept_version
        ) do
      BusinessConceptAbilities.can?(session, :undo_rejection, business_concept_version)
    end

    def can?(%Session{} = session, :publish, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(session, :publish, business_concept_version)
    end

    def can?(%Session{} = session, :version, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(session, :version, business_concept_version)
    end

    def can?(
          %Session{} = session,
          :deprecate,
          %BusinessConceptVersion{} = business_concept_version
        ) do
      BusinessConceptAbilities.can?(session, :deprecate, business_concept_version)
    end

    def can?(%Session{} = session, :delete, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(session, :delete, business_concept_version)
    end

    def can?(
          %Session{} = session,
          :set_confidential,
          %BusinessConceptVersion{} = business_concept_version
        ) do
      BusinessConceptAbilities.can?(
        session,
        :manage_confidential_business_concepts,
        business_concept_version
      )
    end

    def can?(
          %Session{} = session,
          :view_business_concept,
          %BusinessConceptVersion{} = business_concept_version
        ) do
      BusinessConceptAbilities.can?(session, :view_business_concept, business_concept_version)
    end

    def can?(%Session{is_admin: true}, _action, %{}), do: true
    def can?(%Session{}, _action, _domain), do: false
  end
end
