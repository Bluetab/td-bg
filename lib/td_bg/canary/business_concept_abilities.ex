defmodule TdBg.Canary.BusinessConceptAbilities do
  @moduledoc false
  alias TdBg.Accounts.User
  alias TdBg.Taxonomies.Domain
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Permissions
  alias TdBg.Permissions.Permission

  def can?(%User{id: user_id}, :create_business_concept, %Domain{id: domain_id})  do
    %{user_id: user_id,
      permission: Permission.permissions.create_business_concept,
      domain_id: domain_id}
    |> Permissions.authorized?
  end

  def can?(%User{id: user_id}, :update, %BusinessConceptVersion{status: status, business_concept: %BusinessConcept{domain_id: domain_id}}) do
    %{user_id: user_id,
      permission: Permission.permissions.update_business_concept,
      current_status: status,
      required_statuses: [BusinessConcept.status.draft, BusinessConcept.status.rejected],
      domain_id: domain_id}
    |> authorized?
  end

  def can?(%User{id: user_id}, :send_for_approval, %BusinessConceptVersion{status: status, business_concept: %BusinessConcept{domain_id: domain_id}}) do
    %{user_id: user_id,
      permission: Permission.permissions.send_business_concept_for_approval,
      current_status: status,
      required_statuses: [BusinessConcept.status.draft, BusinessConcept.status.rejected],
      domain_id: domain_id}
    |> authorized?
  end

  def can?(%User{id: user_id}, :reject, %BusinessConceptVersion{status: status, business_concept: %BusinessConcept{domain_id: domain_id}}) do
    %{user_id: user_id,
      permission: Permission.permissions.reject_business_concept,
      current_status: status,
      required_statuses: [BusinessConcept.status.pending_approval, BusinessConcept.status.rejected],
      domain_id: domain_id}
    |> authorized?
  end

  def can?(%User{id: user_id}, :publish, %BusinessConceptVersion{status: status, business_concept: %BusinessConcept{domain_id: domain_id}}) do
    %{user_id: user_id,
      permission: Permission.permissions.publish_business_concept,
      current_status: status,
      required_statuses: [BusinessConcept.status.pending_approval],
      domain_id: domain_id}
    |> authorized?
  end

  def can?(%User{id: user_id}, :deprecate, %BusinessConceptVersion{status: status, business_concept: %BusinessConcept{domain_id: domain_id}}) do
    %{user_id: user_id,
      permission: Permission.permissions.deprecate_business_concept,
      current_status: status,
      required_statuses: [BusinessConcept.status.published],
      domain_id: domain_id}
    |> authorized?
  end

  def can?(%User{id: user_id}, :update_published, %BusinessConceptVersion{status: status, business_concept: %BusinessConcept{domain_id: domain_id}}) do
    %{user_id: user_id,
      permission: Permission.permissions.update_business_concept,
      current_status: status,
      required_statuses: [BusinessConcept.status.published],
      domain_id: domain_id}
    |> authorized?
  end

  def can?(%User{id: user_id}, :delete, %BusinessConceptVersion{status: status, business_concept: %BusinessConcept{domain_id: domain_id}}) do
    %{user_id: user_id,
      permission: Permission.permissions.delete_business_concept,
      current_status: status,
      required_statuses: [BusinessConcept.status.draft, BusinessConcept.status.rejected],
      domain_id: domain_id}
    |> authorized?
  end

  def can?(%User{id: user_id}, :view_versions, %BusinessConceptVersion{status: status, business_concept: %BusinessConcept{domain_id: domain_id}}) do
    %{user_id: user_id,
      permission: Permission.permissions.view_versioned_business_concepts,
      current_status: status,
      required_statuses: [BusinessConcept.status.draft, BusinessConcept.status.pending_approval, BusinessConcept.status.rejected,
                          BusinessConcept.status.published, BusinessConcept.status.versioned, BusinessConcept.status.deprecated],
      domain_id: domain_id}
    |> authorized?
  end

  def can?(%User{id: user_id}, :manage_alias, %BusinessConceptVersion{status: status, business_concept: %BusinessConcept{domain_id: domain_id}}) do
    %{user_id: user_id,
      permission: Permission.permissions.manage_business_concept_alias,
      current_status: status,
      required_statuses: [BusinessConcept.status.draft, BusinessConcept.status.published],
      domain_id: domain_id}
    |> authorized?
  end

  def can?(%User{}, _permission, _domain),  do: false

  defp authorized?(%{user_id: user_id,
                     permission: permission,
                     current_status: current_status,
                     required_statuses: required_statuses,
                     domain_id: domain_id}) do
    Enum.member?(required_statuses, current_status) &&
    Permissions.authorized?(%{user_id: user_id,
                              permission: permission,
                              domain_id: domain_id})
  end

end
