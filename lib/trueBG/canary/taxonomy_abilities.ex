defmodule TrueBG.Canary.TaxonomyAbilities do
  @moduledoc false
  alias TrueBG.Accounts.User
  alias TrueBG.Taxonomies.DomainGroup
  alias TrueBG.Permissions

  def can?(%User{id: user_id}, :create_data_domain, %DomainGroup{id: domain_group_id}) do
    acl_params = %{user_id: user_id, domain_group_id: domain_group_id}
    role = Permissions.get_role_in_resource(acl_params)
    case role.name do
      "admin" ->
        true
      name when name in ["watcher" , "creator", "publisher"] ->
        false
      _ ->
        false
    end
  end
end
