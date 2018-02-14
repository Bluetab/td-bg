defmodule TrueBG.Canary.Abilities do
  @moduledoc false
  alias TrueBG.Accounts.User
  alias TrueBG.Taxonomies.DataDomain
  alias TrueBG.Taxonomies.DomainGroup
  alias TrueBG.BusinessConcepts.BusinessConcept
  alias TrueBG.Permissions
  alias TrueBG.Canary.TaxonomyAbilities

  defimpl Canada.Can, for: User do

    #def can?(%User{}, _action, nil),  do: false

    # administrator is superpowerful
    def can?(%User{is_admin: true}, _action, _domain)  do
      true
    end
    # Data domain

    # This is the creation of a business concept in a data domain
    def can?(%User{id: user_id}, :create_business_concept, %DataDomain{id: data_domain_id})  do
      %{user_id: user_id,
        action: :create,
        data_domain_id: data_domain_id}
      |> can_execute_action?
    end

    def can?(%User{} = user, :create_data_domain, %DomainGroup{id: domain_group_id} = domain_group) do
      TaxonomyAbilities.can?(user, :create_data_domain, domain_group)
    end

    def can?(%User{}, _action, BusinessConcept) do  #when action in [:admin, :watch, :creaBusinte, :publish] do
      true
    end

    def can?(%User{id: user_id}, :update, %BusinessConcept{status: status, data_domain_id: data_domain_id}) do
      %{user_id: user_id, action: :update,
        current_status: status,
        required_statuses: [BusinessConcept.status.draft, BusinessConcept.status.published],
        data_domain_id: data_domain_id}
      |> can_execute_action?
    end

    def can?(%User{id: user_id}, :send_for_approval, %BusinessConcept{status: status, data_domain_id: data_domain_id}) do
      %{user_id: user_id, action: :send_for_approval,
        current_status: status,
        required_statuses: [BusinessConcept.status.draft],
        data_domain_id: data_domain_id}
      |> can_execute_action?
    end

    def can?(%User{id: user_id}, :reject, %BusinessConcept{status: status, data_domain_id: data_domain_id}) do
      %{user_id: user_id, action: :reject,
        current_status: status,
        required_statuses: [BusinessConcept.status.pending_approval],
        data_domain_id: data_domain_id}
      |> can_execute_action?
    end

    def can?(%User{id: user_id}, :publish, %BusinessConcept{status: status, data_domain_id: data_domain_id}) do
      %{user_id: user_id, action: :publish,
        current_status: status,
        required_statuses: [BusinessConcept.status.pending_approval],
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
end
