defmodule TdBgWeb.UserController do
  use TdBgWeb, :controller
  alias TdBg.Permissions
  alias TdBg.Permissions.AclEntry
  alias TdBg.Taxonomies
  alias TdBgWeb.UserView

  action_fallback TdBgWeb.FallbackController

  @td_auth_api Application.get_env(:td_bg, :auth_service)[:api_service]

  def create(_conn, %{"user" => _user_params} = req) do
    @td_auth_api.create_user(req)
  end

  def search(_conn, %{"ids" => _ids} = req) do
    @td_auth_api.search_users(req)
  end

  def get_user_domains(_, [], acc), do: Enum.uniq(acc)
  def get_user_domains(d_all, [domain | tail], acc) do
    acc = acc ++ get_child_domain(d_all, domain, [])
    get_user_domains(d_all, tail, acc)
  end

  def get_child_domain(_, [], acc), do: acc
  def get_child_domain(d_all, [d_children | tail], acc) do
    domain = %{id: d_children.id, name: d_children.name}
    acc = get_child_domain(d_all, domain, acc)
    get_child_domain(d_all, tail, acc)
  end
  def get_child_domain(d_all, domain, acc) do
    acc = [domain] ++ acc
    d_children = Enum.filter(d_all, fn(d) -> d.parent_id == domain.id end)
      case d_children do
        [] -> get_child_domain(d_all, d_children, acc)
        domains -> get_child_domain(d_all, domains, acc)
    end
  end

  def user_domains(conn, %{"user_id" => user_id}) do
    d_all = Taxonomies.list_domains()
    acl_list = Permissions.list_acl_entries_by_principal_types(%{principal_types: ["user", "group"]})
    domain_list = retrive_domain_ids_for_user(acl_list, user_id)
    domain_list = domain_list |> map_domain_to_domain_object(d_all)
    response = get_user_domains(d_all, domain_list, [])
    render(conn, UserView, "user_domains.json", %{user_domains: response})
  end

  defp retrive_domain_ids_for_user(acl_list, user_id) do
    user_groups = query_user_groups(user_id)
    final_ids = Enum.reduce(acl_list, [],
      fn(acl, acc) ->
        if are_permissions_in_role_list?(["create_business_concept"], acl) do
            case acl.principal_type do
              "user" -> retrieve_user_domain_id(acl, user_id, acc)
              "group" -> retrieve_group_domain_id(acl, acc, user_groups)
            _ -> acc
          end
        else
          acc
        end
      end)
    Enum.uniq(final_ids)
  end

 defp retrieve_user_domain_id(acl, user_id, acc) do
     case acl.principal_id == String.to_integer(user_id) do
       true -> acc ++ [acl.resource_id]
       false -> acc
     end
 end

 defp retrieve_group_domain_id(acl, acc, user_groups) do
   case Enum.member?(Enum.map(user_groups, &(&1["id"])), acl.principal_id) do
     true -> acc ++ [acl.resource_id]
     false -> acc
   end
 end

 defp map_domain_to_domain_object(domain_list, d_all) do
    Enum.map(domain_list,
       fn(x) ->
        domain_item = Enum.find(d_all, fn(y) -> y.id == x end)
        if domain_item do
          %{id: x, name: domain_item.name}
        end
      end)
 end

 defp are_permissions_in_role_list?(permissions_list, %AclEntry{} =  acl) do
   Enum.any?(permissions_list, fn x -> x in Enum.map(acl.role.permissions, &(&1.name)) end)
 end

 defp query_user_groups(user_id) do
   @td_auth_api.search_groups_by_user_id(user_id)
 end

end
