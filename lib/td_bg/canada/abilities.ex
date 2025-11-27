defmodule TdBg.Canada.Abilities do
  @moduledoc false

  alias TdBg.Auth.Claims
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Canada.BusinessConceptAbilities
  alias TdBg.Canada.LinkAbilities
  alias TdBg.Canada.TaxonomyAbilities
  alias TdBg.Permissions
  alias TdBg.Taxonomies.Domain
  alias TdCache.Link
  alias TdCluster.Cluster.TdAi.Indices

  defimpl Canada.Can, for: Claims do
    @embedding_actions ~w(put_embeddings suggest_concepts)a
    @index_type "suggestions"

    def can?(%Claims{role: "admin"}, action, BusinessConcept) when action in @embedding_actions do
      case Indices.exists_enabled?(index_type: @index_type) do
        {:ok, enabled?} -> enabled?
        _ -> false
      end
    end

    def can?(%Claims{role: "admin"}, _action, BusinessConcept), do: true
    def can?(%Claims{role: "admin"}, _action, %BusinessConcept{}), do: true
    def can?(%Claims{role: "admin"}, _action, Domain), do: true
    def can?(%Claims{role: "admin"}, _action, %Domain{}), do: true
    def can?(%Claims{role: "admin"}, :manage_grant_requests, %{}), do: true

    def can?(%Claims{}, :suggest_concepts, BusinessConcept) do
      case Indices.exists_enabled?(index_type: @index_type) do
        {:ok, enabled?} ->
          enabled?

        _ ->
          false
      end
    end

    def can?(%Claims{} = claims, :manage_grant_requests, %{}) do
      Permissions.has_any_permission?(claims, [
        "create_grant_request",
        "create_foreign_grant_request",
        "manage_grant_removal",
        "manage_foreign_grant_removal"
      ])
    end

    def can?(%Claims{} = claims, action, %Link{} = link) do
      LinkAbilities.can?(claims, action, link)
    end

    def can?(%Claims{} = claims, :create_concept_link, %{business_concept: business_concept}) do
      LinkAbilities.can?(claims, :create_concept_link, business_concept)
    end

    def can?(%Claims{} = claims, :create_structure_link, %{business_concept: business_concept}) do
      LinkAbilities.can?(claims, :create_structure_link, business_concept)
    end

    def can?(
          %Claims{} = claims,
          :create_structure_link,
          %{"business_concept_id" => _} = business_concept
        ) do
      LinkAbilities.can?(claims, :create_structure_link, business_concept)
    end

    def can?(%Claims{} = claims, :suggest_structure_link, %{business_concept: business_concept}) do
      LinkAbilities.can?(claims, :suggest_structure_link, business_concept)
    end

    def can?(
          %Claims{} = claims,
          :suggest_structure_link,
          %{"business_concept_id" => _} = business_concept
        ) do
      LinkAbilities.can?(claims, :suggest_structure_link, business_concept)
    end

    def can?(%Claims{} = claims, :create_implementation, %{} = business_concept) do
      LinkAbilities.can?(claims, :create_implementation, business_concept)
    end

    def can?(%Claims{} = claims, :create_raw_implementation, %{} = business_concept) do
      LinkAbilities.can?(claims, :create_raw_implementation, business_concept)
    end

    def can?(%Claims{} = claims, :create_link_implementation, %{} = business_concept) do
      LinkAbilities.can?(claims, :create_link_implementation, business_concept)
    end

    def can?(%Claims{} = claims, action, %{hint: :link} = resource) do
      LinkAbilities.can?(claims, action, resource)
    end

    def can?(%Claims{} = claims, :list, Domain) do
      TaxonomyAbilities.can?(claims, :list, Domain)
    end

    def can?(%Claims{} = claims, :create, %Domain{} = domain) do
      TaxonomyAbilities.can?(claims, :create, domain)
    end

    def can?(%Claims{} = claims, :update, %Domain{} = domain) do
      TaxonomyAbilities.can?(claims, :update, domain)
    end

    def can?(%Claims{} = claims, :show, %Domain{} = domain) do
      TaxonomyAbilities.can?(claims, :show, domain)
    end

    def can?(%Claims{} = claims, :delete, %Domain{} = domain) do
      TaxonomyAbilities.can?(claims, :delete, domain)
    end

    def can?(%Claims{} = claims, :move, %Domain{} = domain) do
      TaxonomyAbilities.can?(claims, :move, domain)
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

    def can?(%Claims{} = claims, :manage_data_sources, %Domain{} = domain) do
      TaxonomyAbilities.can?(claims, :manage_data_sources, domain)
    end

    def can?(%Claims{} = claims, :manage_configurations, %Domain{} = domain) do
      TaxonomyAbilities.can?(claims, :manage_configurations, domain)
    end

    def can?(%Claims{} = claims, :update_data_structure, %Domain{} = domain) do
      TaxonomyAbilities.can?(claims, :update_data_structure, domain)
    end

    def can?(%Claims{} = claims, :view_data_structure, domain_id) do
      TaxonomyAbilities.can?(claims, :view_data_structure, domain_id)
    end

    def can?(%Claims{} = claims, :manage_quality_rule, %Domain{} = domain) do
      TaxonomyAbilities.can?(claims, :manage_quality_rule, domain)
    end

    def can?(%Claims{} = claims, :manage_quality_rule_implementations, %Domain{} = domain) do
      TaxonomyAbilities.can?(claims, :manage_quality_rule_implementations, domain)
    end

    def can?(%Claims{} = claims, :manage_raw_quality_rule_implementations, %Domain{} = domain) do
      TaxonomyAbilities.can?(claims, :manage_raw_quality_rule_implementations, domain)
    end

    def can?(%Claims{} = claims, :manage_ruleless_implementations, %Domain{} = domain) do
      TaxonomyAbilities.can?(claims, :manage_ruleless_implementations, domain)
    end

    def can?(%Claims{} = claims, :manage_structures_domain, %Domain{} = domain) do
      TaxonomyAbilities.can?(claims, :manage_structures_domain, domain)
    end

    def can?(%Claims{} = claims, :update_ingest, %Domain{} = domain) do
      TaxonomyAbilities.can?(claims, :update_ingest, domain)
    end

    def can?(%Claims{} = claims, :view_dashboard, %Domain{} = domain) do
      TaxonomyAbilities.can?(claims, :view_dashboard, domain)
    end

    def can?(%Claims{} = claims, :view_quality_rule, %Domain{} = domain) do
      TaxonomyAbilities.can?(claims, :view_quality_rule, domain)
    end

    def can?(%Claims{} = claims, :create, BusinessConceptVersion) do
      BusinessConceptAbilities.can?(claims, :create_business_concept)
    end

    def can?(%Claims{} = claims, action, BusinessConceptVersion)
        when action in [
               :download_published_concepts,
               :download_deprecated_concepts,
               :download_draft_concepts
             ] do
      BusinessConceptAbilities.can?(claims, action)
    end

    def can?(%Claims{} = claims, :download_links, BusinessConceptVersion) do
      LinkAbilities.can?(claims, :download_links)
    end

    def can?(%Claims{} = claims, :upload, BusinessConceptVersion) do
      BusinessConceptAbilities.can?(claims, :create_business_concept)
    end

    def can?(%Claims{} = claims, :upload, BusinessConcept) do
      BusinessConceptAbilities.can?(claims, :create_business_concept)
    end

    def can?(%Claims{} = claims, :upload, %Domain{} = domain) do
      BusinessConceptAbilities.can?(claims, :create_business_concept, domain)
    end

    def can?(%Claims{} = claims, :share_with_domain, %BusinessConcept{} = business_concept) do
      BusinessConceptAbilities.can?(claims, :share_with_domain, business_concept)
    end

    def can?(%Claims{} = claims, :auto_publish, BusinessConceptVersion) do
      BusinessConceptAbilities.can?(claims, :auto_publish, BusinessConcept)
    end

    def can?(
          %Claims{} = claims,
          :auto_publish,
          %BusinessConceptVersion{} = business_concept_version
        ) do
      BusinessConceptAbilities.can?(claims, :auto_publish, business_concept_version)
    end

    def can?(%Claims{} = claims, :manage_business_concepts_domain, %Domain{} = domain) do
      BusinessConceptAbilities.can?(claims, :manage_business_concepts_domain, domain)
    end

    def can?(%Claims{} = claims, :update_domain, %{business_concept: %{domain: domain}}) do
      BusinessConceptAbilities.can?(claims, :manage_business_concepts_domain, domain)
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

    def can?(%Claims{} = claims, :restore, %BusinessConceptVersion{} = business_concept_version) do
      BusinessConceptAbilities.can?(claims, :restore, business_concept_version)
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
