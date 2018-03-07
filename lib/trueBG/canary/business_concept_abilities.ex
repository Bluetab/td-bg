defmodule TdBG.Canary.BusinessConceptAbilities do
  @moduledoc false
  alias TdBG.Accounts.User
  alias TdBG.Taxonomies.DataDomain
  alias TdBG.BusinessConcepts.BusinessConcept
  alias TdBG.BusinessConcepts.BusinessConceptVersion
  alias TdBG.Permissions

  def can?(%User{id: user_id}, :create_business_concept, %DataDomain{id: data_domain_id})  do
    %{user_id: user_id,
      action: :create,
      data_domain_id: data_domain_id}
    |> can_execute_action?
  end

  def can?(%User{id: user_id}, :update, %BusinessConceptVersion{status: status, business_concept: %BusinessConcept{data_domain_id: data_domain_id}}) do
    %{user_id: user_id, action: :update,
      current_status: status,
      required_statuses: [BusinessConcept.status.draft, BusinessConcept.status.published],
      data_domain_id: data_domain_id}
    |> can_execute_action?
  end

  def can?(%User{id: user_id}, :send_for_approval, %BusinessConceptVersion{status: status, business_concept: %BusinessConcept{data_domain_id: data_domain_id}}) do
    %{user_id: user_id, action: :send_for_approval,
      current_status: status,
      required_statuses: [BusinessConcept.status.draft],
      data_domain_id: data_domain_id}
    |> can_execute_action?
  end

  def can?(%User{id: user_id}, :reject, %BusinessConceptVersion{status: status, business_concept: %BusinessConcept{data_domain_id: data_domain_id}}) do
    %{user_id: user_id, action: :reject,
      current_status: status,
      required_statuses: [BusinessConcept.status.pending_approval],
      data_domain_id: data_domain_id}
    |> can_execute_action?
  end

  def can?(%User{id: user_id}, :publish, %BusinessConceptVersion{status: status, business_concept: %BusinessConcept{data_domain_id: data_domain_id}}) do
    %{user_id: user_id, action: :publish,
      current_status: status,
      required_statuses: [BusinessConcept.status.pending_approval],
      data_domain_id: data_domain_id}
    |> can_execute_action?
  end

  def can?(%User{id: user_id}, :update_published, %BusinessConceptVersion{status: status, business_concept: %BusinessConcept{data_domain_id: data_domain_id}}) do
    %{user_id: user_id, action: :update,
      current_status: status,
      required_statuses: [BusinessConcept.status.published],
      data_domain_id: data_domain_id}
    |> can_execute_action?
  end

  def can?(%User{id: user_id}, :delete, %BusinessConceptVersion{status: status, business_concept: %BusinessConcept{data_domain_id: data_domain_id}}) do
    %{user_id: user_id, action: :delete,
      current_status: status,
      required_statuses: [BusinessConcept.status.draft, BusinessConcept.status.rejected],
      data_domain_id: data_domain_id}
    |> can_execute_action?
  end

  def can?(%User{}, _action, _domain),  do: false

  defp can_execute_action?(%{user_id: _user_id,
                             action: _action,
                             current_status: current_status,
                             required_statuses: required_statuses,
                             data_domain_id: _data_domain_id} = params) do
    (params |> allowed_action?) &&
    Enum.member?(required_statuses, current_status)
  end

  defp can_execute_action?(%{user_id: _user_id,
                             action: _action,
                             data_domain_id: _data_domain_id} = params) do
    params |> allowed_action?
  end

  defp allowed_action?(%{user_id: user_id, action: action,
                             data_domain_id: data_domain_id}) do

    role_name = %{user_id: user_id, data_domain_id: data_domain_id}
    |> Permissions.get_role_in_resource
    |> Map.get(:name)
    |> String.to_atom

    permissions = BusinessConcept.get_permissions()

    permissions
    |> Map.get(role_name)
    |> Enum.member?(action)
  end

end
