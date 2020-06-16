defmodule TdBg.Canada.BusinessConceptAbilities do
  @moduledoc false

  alias TdBg.Accounts.User
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

  def can?(%User{is_admin: true}, :create_business_concept), do: true

  def can?(%User{} = user, :create_business_concept) do
    Permissions.has_any_permission_on_resource_type?(
      user,
      [:create_business_concept],
      Domain
    )
  end

  def can?(%User{} = user, :create_business_concept, %Domain{
        id: domain_id
      }) do
    Permissions.authorized?(user, :create_business_concept, domain_id)
  end

  def can?(%User{} = user, :create_ingest, %Domain{
        id: domain_id
      }) do
    Permissions.authorized?(user, :create_ingest, domain_id)
  end

  def can?(%User{} = user, :update, %BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.is_updatable?(business_concept_version) &&
      authorized?(
        user,
        :update_business_concept,
        business_concept_version
      )
  end

  def can?(
        %User{} = user,
        :get_data_structures,
        %BusinessConceptVersion{} = business_concept_version
      ) do
    authorized?(
      user,
      :update_business_concept,
      business_concept_version
    )
  end

  def can?(
        %User{} = user,
        :send_for_approval,
        %BusinessConceptVersion{} = business_concept_version
      ) do
    BusinessConceptVersion.is_updatable?(business_concept_version) &&
      authorized?(
        user,
        :update_business_concept,
        business_concept_version
      )
  end

  def can?(%User{} = user, :reject, %BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.is_rejectable?(business_concept_version) &&
      authorized?(
        user,
        :reject_business_concept,
        business_concept_version
      )
  end

  def can?(%User{} = user, :undo_rejection, %BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.is_undo_rejectable?(business_concept_version) &&
      authorized?(
        user,
        :update_business_concept,
        business_concept_version
      )
  end

  def can?(%User{} = user, :publish, %BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.is_publishable?(business_concept_version) &&
      authorized?(
        user,
        :publish_business_concept,
        business_concept_version
      )
  end

  def can?(%User{} = user, :version, %BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.is_versionable?(business_concept_version) &&
      authorized?(
        user,
        :update_business_concept,
        business_concept_version
      )
  end

  def can?(%User{} = user, :deprecate, %BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.is_deprecatable?(business_concept_version) &&
      authorized?(
        user,
        :deprecate_business_concept,
        business_concept_version
      )
  end

  def can?(%User{} = user, :delete, %BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.is_deletable?(business_concept_version) &&
      authorized?(
        user,
        :delete_business_concept,
        business_concept_version
      )
  end

  def can?(%User{is_admin: true}, :view_business_concept, %BusinessConceptVersion{}), do: true

  def can?(
        %User{} = user,
        :view_business_concept,
        %BusinessConceptVersion{status: status} = business_concept_version
      ) do
    permission = Map.get(@status_to_permission, status)
    authorized?(user, permission, business_concept_version)
  end

  def can?(%User{}, _action, _business_concept_version), do: false

  defp authorized?(%User{is_admin: true}, _permission, _), do: true

  defp authorized?(%User{} = user, permission, %BusinessConceptVersion{
         content: content,
         business_concept: business_concept
       }) do
    domain_id = business_concept.domain_id

    case is_confidential?(content) do
      true ->
        Permissions.authorized?(user, :manage_confidential_business_concepts, domain_id) &&
          Permissions.authorized?(user, permission, domain_id)

      false ->
        Permissions.authorized?(user, permission, domain_id)
    end
  end

  defp is_confidential?(content) do
    case Map.get(content, "_confidential", "No") do
      "Si" -> true
      _ -> false
    end
  end
end
