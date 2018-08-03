defmodule TdBg.Canada.BusinessConceptAbilities do
  @moduledoc false
  alias TdBg.Accounts.User
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Permissions
  alias TdBg.Taxonomies.Domain

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

  def can?(%User{} = user, :get_data_fields, %BusinessConceptVersion{} = business_concept_version) do
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

  # TODO: Check status is versioned??
  def can?(%User{is_admin: true}, :view_versions, %BusinessConceptVersion{}), do: true

  def can?(%User{} = user, :view_versions, %BusinessConceptVersion{} = business_concept_version) do
    valid_statuses = [
      BusinessConcept.status().draft,
      BusinessConcept.status().pending_approval,
      BusinessConcept.status().rejected,
      BusinessConcept.status().published,
      BusinessConcept.status().versioned,
      BusinessConcept.status().deprecated
    ]

    # TODO: Should be only BusinessConcept.status().versioned??
    BusinessConceptVersion.has_any_status?(business_concept_version, valid_statuses) &&
      authorized?(
        user,
        :view_versioned_business_concepts,
        business_concept_version
      )
  end

  def can?(%User{is_admin: true}, :view_business_concept, %BusinessConceptVersion{}), do: true

  def can?(
        %User{} = user,
        :view_business_concept,
        %BusinessConceptVersion{status: status} = business_concept_version
      ) do
    permission = Map.get(BusinessConcept.status_to_permissions(), status)
    authorized?(user, permission, business_concept_version)
  end

  def can?(%User{} = user, :manage_alias, %BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.is_updatable?(business_concept_version) &&
      authorized?(
        user,
        :manage_business_concept_alias,
        business_concept_version
      )
  end

  def can?(%User{}, _action, _business_concept_version), do: false

  defp authorized?(%User{is_admin: true}, _permission, _), do: true

  defp authorized?(%User{} = user, permission, %BusinessConceptVersion{
         business_concept: business_concept
       }) do
    authorized?(user, permission, business_concept)
  end

  defp authorized?(%User{} = user, permission, %BusinessConcept{domain_id: domain_id}) do
    Permissions.authorized?(user, permission, domain_id)
  end
end
