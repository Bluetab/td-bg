defmodule TdBg.Canada.BusinessConceptAbilities do
  @moduledoc false

  alias TdBg.Auth.Claims
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Permissions
  alias TdBg.Taxonomies.Domain

  @status_to_permission %{
    "pending_approval" => :view_approval_pending_business_concepts,
    "deprecated" => :view_deprecated_business_concepts,
    "draft" => :view_draft_business_concepts,
    "published" => :view_published_business_concepts,
    "rejected" => :view_rejected_business_concepts,
    "versioned" => :view_versioned_business_concepts
  }

  @shared_permissions [
    :view_approval_pending_business_concepts,
    :view_deprecated_business_concepts,
    :view_draft_business_concepts,
    :view_published_business_concepts,
    :view_rejected_business_concepts,
    :view_versioned_business_concepts
  ]

  def can?(%Claims{role: "admin"}, :create_business_concept), do: true

  def can?(%Claims{} = claims, :create_business_concept) do
    Permissions.has_permission?(claims, :create_business_concept)
  end

  def can?(%Claims{role: "admin"}, :download_published_concepts), do: true
  def can?(%Claims{role: "admin"}, :download_deprecated_concepts), do: true
  def can?(%Claims{role: "admin"}, :download_draft_concepts), do: true

  def can?(%Claims{} = claims, :download_published_concepts) do
    Permissions.has_permission?(claims, :view_published_business_concepts)
  end

  def can?(%Claims{} = claims, :download_deprecated_concepts) do
    Permissions.has_permission?(claims, :view_deprecated_business_concepts)
  end

  def can?(%Claims{} = claims, :download_draft_concepts) do
    Permissions.has_permission?(claims, :view_draft_business_concepts) ||
      Permissions.has_permission?(claims, :view_rejected_business_concepts) ||
      Permissions.has_permission?(claims, :view_approval_pending_business_concepts)
  end

  def can?(%Claims{} = claims, :download_links) do
    Permissions.has_permission?(claims, :manage_business_concept_links)
  end

  def can?(%Claims{role: "admin"}, :auto_publish, _), do: true

  def can?(%Claims{} = claims, :auto_publish, BusinessConcept) do
    Permissions.has_permission?(claims, :publish_business_concept)
  end

  def can?(
        %Claims{} = claims,
        :auto_publish,
        %BusinessConceptVersion{} = business_concept_version
      ) do
    authorized?(
      claims,
      :publish_business_concept,
      business_concept_version
    )
  end

  def can?(%Claims{} = claims, :share_with_domain, %BusinessConcept{} = business_concept) do
    authorized?(claims, :share_with_domain, business_concept)
  end

  def can?(%Claims{} = claims, :create_business_concept, %Domain{
        id: domain_id
      }) do
    Permissions.authorized?(claims, :create_business_concept, domain_id)
  end

  def can?(%Claims{} = claims, :create_ingest, %Domain{
        id: domain_id
      }) do
    Permissions.authorized?(claims, :create_ingest, domain_id)
  end

  def can?(%Claims{role: "admin"}, :manage_business_concepts_domain, _), do: true

  def can?(%Claims{} = claims, :manage_business_concepts_domain, %Domain{id: domain_id}) do
    Permissions.authorized?(claims, :manage_business_concepts_domain, domain_id)
  end

  def can?(%Claims{} = claims, :update_business_concept, %Domain{
        id: domain_id
      }) do
    Permissions.authorized?(claims, :update_business_concept, domain_id)
  end

  def can?(%Claims{} = claims, :update, %BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.updatable?(business_concept_version) &&
      authorized?(
        claims,
        :update_business_concept,
        business_concept_version
      )
  end

  def can?(%Claims{} = claims, :update, %BusinessConcept{} = business_concept) do
    authorized?(
      claims,
      :update_business_concept,
      business_concept
    )
  end

  def can?(
        %Claims{} = claims,
        :get_data_structures,
        %BusinessConceptVersion{} = business_concept_version
      ) do
    authorized?(
      claims,
      :update_business_concept,
      business_concept_version
    )
  end

  def can?(
        %Claims{} = claims,
        :send_for_approval,
        %BusinessConceptVersion{} = business_concept_version
      ) do
    BusinessConceptVersion.updatable?(business_concept_version) &&
      authorized?(
        claims,
        :send_business_concept_for_approval,
        business_concept_version
      )
  end

  def can?(%Claims{} = claims, :reject, %BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.rejectable?(business_concept_version) &&
      authorized?(
        claims,
        :reject_business_concept,
        business_concept_version
      )
  end

  def can?(
        %Claims{} = claims,
        :undo_rejection,
        %BusinessConceptVersion{} = business_concept_version
      ) do
    BusinessConceptVersion.undo_rejectable?(business_concept_version) &&
      authorized?(
        claims,
        :update_business_concept,
        business_concept_version
      )
  end

  def can?(%Claims{} = claims, :publish, %BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.publishable?(business_concept_version) &&
      authorized?(
        claims,
        :publish_business_concept,
        business_concept_version
      )
  end

  def can?(%Claims{} = claims, :restore, %BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.restorable?(business_concept_version) &&
      authorized?(
        claims,
        :publish_business_concept,
        business_concept_version
      )
  end

  def can?(%Claims{} = claims, :version, %BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.versionable?(business_concept_version) &&
      authorized?(
        claims,
        :update_business_concept,
        business_concept_version
      )
  end

  def can?(%Claims{} = claims, :deprecate, %BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.deprecatable?(business_concept_version) &&
      authorized?(
        claims,
        :deprecate_business_concept,
        business_concept_version
      )
  end

  def can?(%Claims{} = claims, :delete, %BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.deletable?(business_concept_version) &&
      authorized?(
        claims,
        :delete_business_concept,
        business_concept_version
      )
  end

  def can?(%Claims{role: role}, :view_business_concept, %BusinessConceptVersion{})
      when role in ["admin", "service"],
      do: true

  def can?(
        %Claims{} = claims,
        :view_business_concept,
        %BusinessConceptVersion{status: status} = business_concept_version
      ) do
    permission = Map.get(@status_to_permission, status)
    authorized?(claims, permission, business_concept_version)
  end

  def can?(
        %Claims{} = claims,
        :manage_confidential_business_concepts,
        %BusinessConceptVersion{} = business_concept_version
      ) do
    authorized?(claims, :manage_confidential_business_concepts, business_concept_version)
  end

  def can?(%Claims{}, _action, _business_concept_version), do: false

  defp authorized?(%Claims{role: "admin"}, _permission, _), do: true

  defp authorized?(%Claims{} = claims, permission, %BusinessConceptVersion{
         business_concept: business_concept
       }) do
    authorized_business_concept(claims, permission, business_concept)
  end

  defp authorized?(%Claims{} = claims, permission, %BusinessConcept{} = business_concept) do
    authorized_business_concept(claims, permission, business_concept)
  end

  defp authorized_business_concept(
         %Claims{} = claims,
         permission,
         %BusinessConcept{confidential: confidential} = concept
       )
       when permission in @shared_permissions do
    domain_ids = BusinessConcepts.get_domain_ids(concept)
    authorized_business_concept(claims, permission, confidential, domain_ids)
  end

  defp authorized_business_concept(
         %Claims{} = claims,
         permission,
         %BusinessConcept{confidential: confidential, domain_id: domain_id}
       ) do
    authorized_business_concept(claims, permission, confidential, domain_id)
  end

  defp authorized_business_concept(
         %Claims{} = claims,
         permission,
         false = _confidential,
         domain_id_or_ids
       ) do
    Permissions.authorized?(claims, permission, domain_id_or_ids)
  end

  defp authorized_business_concept(
         %Claims{} = claims,
         permission,
         true = _confidential,
         domain_id_or_ids
       ) do
    Permissions.authorized?(claims, :manage_confidential_business_concepts, domain_id_or_ids) &&
      Permissions.authorized?(claims, permission, domain_id_or_ids)
  end
end
