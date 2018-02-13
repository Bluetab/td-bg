defmodule TrueBG.Permissions.Abilities do
  @moduledoc false
  alias TrueBG.Accounts.User
  alias TrueBG.Taxonomies.DataDomain
  alias TrueBG.BusinessConcepts.BusinessConcept
  alias TrueBG.Permissions

  defimpl Canada.Can, for: User do

    #def can?(%User{}, _action, nil),  do: false

    # administrator is superpowerful
    def can?(%User{is_admin: true}, _action, _domain),  do: true

    # Data domain

    # This is the creation of a business concept in a data domain
    def can?(%User{id: user_id}, :create_business_concept, %DataDomain{id: data_domain_id})  do
      %{user_id: user_id,
        action: :create,
        data_domain_id: data_domain_id}
      |> can_execute_action?
    end

    def can?(%User{}, _action, %DataDomain{}) do  #when action in [:admin, :watch, :create, :publish] do
      true
    end

    def can?(%User{}, _action, DataDomain) do  #when action in [:admin, :watch, :creaBusinte, :publish] do
      true
    end

    def can?(%User{}, _action, BusinessConcept) do  #when action in [:admin, :watch, :creaBusinte, :publish] do
      true
    end

    def can?(%User{id: user_id}, :update, %BusinessConcept{status: status, data_domain_id: data_domain_id}) do
      %{user_id: user_id, action: :update,
        current_status: String.to_atom(status),
        required_status: BusinessConcept.draft,
        data_domain_id: data_domain_id}
      |> can_execute_action?
    end

    def can?(%User{id: user_id}, :send_for_approval, %BusinessConcept{status: status, data_domain_id: data_domain_id}) do
      %{user_id: user_id, action: :send_for_approval,
        current_status: String.to_atom(status),
        required_status: BusinessConcept.draft,
        data_domain_id: data_domain_id}
      |> can_execute_action?
    end

    def can?(%User{id: user_id}, :reject, %BusinessConcept{status: status, data_domain_id: data_domain_id}) do
      %{user_id: user_id, action: :reject,
        current_status: String.to_atom(status),
        required_status: BusinessConcept.pending_approval,
        data_domain_id: data_domain_id}
      |> can_execute_action?
    end

    def can?(%User{id: user_id}, :publish, %BusinessConcept{status: status, data_domain_id: data_domain_id}) do
      %{user_id: user_id, action: :publish,
        current_status: String.to_atom(status),
        required_status: BusinessConcept.pending_approval,
        data_domain_id: data_domain_id}
      |> can_execute_action?
    end

    def can?(%User{}, _action, _domain),  do: false

    defp can_execute_action?(%{user_id: _user_id,
                               action: _action,
                               current_status: current_status,
                               required_status: required_status,
                               data_domain_id: _data_domain_id} = params) do
      (params |> allowed_action?) && current_status == required_status
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
