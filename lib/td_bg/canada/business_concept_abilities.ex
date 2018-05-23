defmodule TdBg.Canada.BusinessConceptAbilities do
  @moduledoc false
  alias TdBg.Accounts.User
  alias TdBg.Taxonomies.Domain
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Permissions
  alias TdBg.Permissions.Permission

  def can?(%User{id: user_id, is_admin: is_admin}, :create_business_concept, %Domain{id: domain_id})  do
    %{user_id: user_id,
      is_admin: is_admin,
      permission: Permission.permissions.create_business_concept,
      domain_id: domain_id}
    |> Permissions.authorized?
  end

  def can?(%User{id: user_id, is_admin: is_admin}, :update, %BusinessConceptVersion{current: is_current, status: status, business_concept: %BusinessConcept{domain_id: domain_id}}) do
    %{user_id: user_id,
      is_admin: is_admin,
      permission: Permission.permissions.update_business_concept,
      is_current: is_current,
      current_status: status,
      required_statuses: [BusinessConcept.status.draft],
      domain_id: domain_id}
    |> authorized?
  end

  def can?(%User{id: user_id, is_admin: is_admin}, :send_for_approval, %BusinessConceptVersion{current: is_current, status: status, business_concept: %BusinessConcept{domain_id: domain_id}}) do
    %{user_id: user_id,
      is_admin: is_admin,
      permission: Permission.permissions.send_business_concept_for_approval,
      is_current: is_current,
      current_status: status,
      required_statuses: [BusinessConcept.status.draft],
      domain_id: domain_id}
    |> authorized?
  end

  def can?(%User{id: user_id, is_admin: is_admin}, :reject, %BusinessConceptVersion{current: is_current, status: status, business_concept: %BusinessConcept{domain_id: domain_id}}) do
    %{user_id: user_id,
      is_admin: is_admin,
      permission: Permission.permissions.reject_business_concept,
      is_current: is_current,
      current_status: status,
      required_statuses: [BusinessConcept.status.pending_approval],
      domain_id: domain_id}
    |> authorized?
  end

  def can?(%User{id: user_id, is_admin: is_admin}, :undo_rejection, %BusinessConceptVersion{current: is_current, status: status, business_concept: %BusinessConcept{domain_id: domain_id}}) do
    %{user_id: user_id,
      is_admin: is_admin,
      permission: Permission.permissions.update_business_concept,
      is_current: is_current,
      current_status: status,
      required_statuses: [BusinessConcept.status.rejected],
      domain_id: domain_id}
    |> authorized?
  end

  def can?(%User{id: user_id, is_admin: is_admin}, :publish, %BusinessConceptVersion{current: is_current, status: status, business_concept: %BusinessConcept{domain_id: domain_id}}) do
    %{user_id: user_id,
      is_admin: is_admin,
      permission: Permission.permissions.publish_business_concept,
      is_current: is_current,
      current_status: status,
      required_statuses: [BusinessConcept.status.pending_approval],
      domain_id: domain_id}
    |> authorized?
  end

  def can?(%User{id: user_id, is_admin: is_admin}, :version, %BusinessConceptVersion{current: is_current, status: status, business_concept: %BusinessConcept{domain_id: domain_id}}) do
    %{user_id: user_id,
      is_admin: is_admin,
      permission: Permission.permissions.update_business_concept,
      is_current: is_current,
      current_status: status,
      required_statuses: [BusinessConcept.status.published],
      domain_id: domain_id}
    |> authorized?
  end

  def can?(%User{id: user_id, is_admin: is_admin}, :deprecate, %BusinessConceptVersion{current: is_current, status: status, business_concept: %BusinessConcept{domain_id: domain_id}}) do
    %{user_id: user_id,
      is_admin: is_admin,
      permission: Permission.permissions.deprecate_business_concept,
      is_current: is_current,
      current_status: status,
      required_statuses: [BusinessConcept.status.published],
      domain_id: domain_id}
    |> authorized?
  end

  def can?(%User{id: user_id, is_admin: is_admin}, :delete, %BusinessConceptVersion{current: is_current, status: status, business_concept: %BusinessConcept{domain_id: domain_id}}) do
    %{user_id: user_id,
      is_admin: is_admin,
      permission: Permission.permissions.delete_business_concept,
      is_current: is_current,
      current_status: status,
      required_statuses: [BusinessConcept.status.draft, BusinessConcept.status.rejected],
      domain_id: domain_id}
    |> authorized?
  end

  def can?(%User{id: user_id, is_admin: is_admin}, :view_versions, %BusinessConceptVersion{current: is_current, status: status, business_concept: %BusinessConcept{domain_id: domain_id}}) do
    %{user_id: user_id,
      is_admin: is_admin,
      permission: Permission.permissions.view_versioned_business_concepts,
      is_current: is_current,
      current_status: status,
      required_statuses: [BusinessConcept.status.draft, BusinessConcept.status.pending_approval, BusinessConcept.status.rejected,
                          BusinessConcept.status.published, BusinessConcept.status.versioned, BusinessConcept.status.deprecated],
      domain_id: domain_id}
    |> authorized?
  end

  def can?(user, :view_business_concept, %BusinessConceptVersion{status: status, business_concept: %BusinessConcept{domain_id: domain_id}}) do
    can?(user, :view_business_concept, {status, domain_id})
  end

  def can?(%User{is_admin: true}, :view_business_concept, _any_domain_and_status) do
    true
  end

  def can?(%User{id: user_id}, :view_business_concept, {status, domain_id}) do
    %{user_id: user_id,
      permission: Map.get(BusinessConcept.status_to_permissions, status),
      domain_id: domain_id}
    |> Permissions.authorized?
  end

  def can?(%User{id: user_id, is_admin: is_admin}, :manage_alias, %BusinessConceptVersion{current: is_current, status: status, business_concept: %BusinessConcept{domain_id: domain_id}}) do
    %{user_id: user_id,
      is_admin: is_admin,
      permission: Permission.permissions.manage_business_concept_alias,
      is_current: is_current,
      current_status: status,
      required_statuses: [BusinessConcept.status.draft, BusinessConcept.status.published],
      domain_id: domain_id}
    |> authorized?
  end

  def can?(%User{}, _permission, _domain),  do: false

  defp authorized?(%{is_admin: true,
                     is_current: is_current,
                     current_status: current_status,
                     required_statuses: required_statuses}) do
    is_current && Enum.member?(required_statuses, current_status)
  end

  defp authorized?(%{user_id: user_id,
                     permission: permission,
                     is_current: is_current,
                     current_status: current_status,
                     required_statuses: required_statuses,
                     domain_id: domain_id}) do
    is_current &&
    Enum.member?(required_statuses, current_status) &&
    Permissions.authorized?(%{user_id: user_id,
                              permission: permission,
                              domain_id: domain_id})
  end

end
