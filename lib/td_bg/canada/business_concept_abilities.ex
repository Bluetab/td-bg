defmodule TdBg.Canada.BusinessConceptAbilities do
  @moduledoc false

  alias TdBg.Accounts.Session
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

  def can?(%Session{is_admin: true}, :create_business_concept), do: true

  def can?(%Session{} = session, :create_business_concept) do
    Permissions.has_any_permission_on_resource_type?(
      session,
      [:create_business_concept],
      Domain
    )
  end

  def can?(%Session{} = session, :create_business_concept, %Domain{
        id: domain_id
      }) do
    Permissions.authorized?(session, :create_business_concept, domain_id)
  end

  def can?(%Session{} = session, :create_ingest, %Domain{
        id: domain_id
      }) do
    Permissions.authorized?(session, :create_ingest, domain_id)
  end

  def can?(%Session{} = session, :update_business_concept, %Domain{
        id: domain_id
      }) do
    Permissions.authorized?(session, :update_business_concept, domain_id)
  end

  def can?(%Session{} = session, :update, %BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.is_updatable?(business_concept_version) &&
      authorized?(
        session,
        :update_business_concept,
        business_concept_version
      )
  end

  def can?(%Session{} = session, :update, %BusinessConcept{} = business_concept) do
    authorized?(
      session,
      :update_business_concept,
      business_concept
    )
  end

  def can?(
        %Session{} = session,
        :get_data_structures,
        %BusinessConceptVersion{} = business_concept_version
      ) do
    authorized?(
      session,
      :update_business_concept,
      business_concept_version
    )
  end

  def can?(
        %Session{} = session,
        :send_for_approval,
        %BusinessConceptVersion{} = business_concept_version
      ) do
    BusinessConceptVersion.is_updatable?(business_concept_version) &&
      authorized?(
        session,
        :send_business_concept_for_approval,
        business_concept_version
      )
  end

  def can?(%Session{} = session, :reject, %BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.is_rejectable?(business_concept_version) &&
      authorized?(
        session,
        :reject_business_concept,
        business_concept_version
      )
  end

  def can?(
        %Session{} = session,
        :undo_rejection,
        %BusinessConceptVersion{} = business_concept_version
      ) do
    BusinessConceptVersion.is_undo_rejectable?(business_concept_version) &&
      authorized?(
        session,
        :update_business_concept,
        business_concept_version
      )
  end

  def can?(%Session{} = session, :publish, %BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.is_publishable?(business_concept_version) &&
      authorized?(
        session,
        :publish_business_concept,
        business_concept_version
      )
  end

  def can?(%Session{} = session, :version, %BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.is_versionable?(business_concept_version) &&
      authorized?(
        session,
        :update_business_concept,
        business_concept_version
      )
  end

  def can?(%Session{} = session, :deprecate, %BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.is_deprecatable?(business_concept_version) &&
      authorized?(
        session,
        :deprecate_business_concept,
        business_concept_version
      )
  end

  def can?(%Session{} = session, :delete, %BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.is_deletable?(business_concept_version) &&
      authorized?(
        session,
        :delete_business_concept,
        business_concept_version
      )
  end

  def can?(%Session{is_admin: true}, :view_business_concept, %BusinessConceptVersion{}), do: true

  def can?(
        %Session{} = session,
        :view_business_concept,
        %BusinessConceptVersion{status: status} = business_concept_version
      ) do
    permission = Map.get(@status_to_permission, status)
    authorized?(session, permission, business_concept_version)
  end

  def can?(
        %Session{} = session,
        :manage_confidential_business_concepts,
        %BusinessConceptVersion{} = business_concept_version
      ) do
    authorized?(session, :manage_confidential_business_concepts, business_concept_version)
  end

  def can?(%Session{}, _action, _business_concept_version), do: false

  defp authorized?(%Session{is_admin: true}, _permission, _), do: true

  defp authorized?(%Session{} = session, permission, %BusinessConceptVersion{
         business_concept: business_concept
       }) do
    authorized_business_concept(session, permission, business_concept)
  end

  defp authorized?(%Session{} = session, permission, %BusinessConcept{} = business_concept) do
    authorized_business_concept(session, permission, business_concept)
  end

  defp authorized_business_concept(
         %Session{} = session,
         permission,
         %BusinessConcept{} = business_concept
       ) do
    domain_id = business_concept.domain_id

    case business_concept.confidential do
      true ->
        Permissions.authorized?(session, :manage_confidential_business_concepts, domain_id) &&
          Permissions.authorized?(session, permission, domain_id)

      false ->
        Permissions.authorized?(session, permission, domain_id)
    end
  end
end
