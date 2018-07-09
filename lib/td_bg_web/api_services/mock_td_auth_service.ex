defmodule TdBgWeb.ApiServices.MockTdAuthService do
  @moduledoc false

  use Agent

  alias TdBg.Accounts.Group
  alias TdBg.Accounts.User
  alias TdBg.Permissions.MockPermissionResolver
  alias TdBg.Taxonomies

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: MockTdAuthService)
  end

  def set_users(user_list) do
    Agent.update(MockTdAuthService, &Map.put(&1, :users, user_list))
  end

  def create_user(%{
        "user" => %{
          "user_name" => user_name,
          "full_name" => full_name,
          "is_admin" => is_admin,
          "password" => password,
          "email" => email,
          "groups" => groups
        }
      }) do
    created_groups =
      groups
      |> Enum.map(&create_group(%{"group" => &1}))

    new_user = %User{
      id: User.gen_id_from_user_name(user_name),
      user_name: user_name,
      full_name: full_name,
      password: password,
      is_admin: is_admin,
      email: email,
      gids: created_groups |> Enum.map(& &1.id),
      groups: created_groups |> Enum.map(& &1.name)
    }

    users = index()
    Agent.update(MockTdAuthService, &Map.put(&1, :users, users ++ [new_user]))
    new_user
  end

  def get_user_by_name(user_name) do
    List.first(Enum.filter(index(), &(&1.user_name == user_name)))
  end

  def search_users(%{"ids" => ids}) do
    Enum.filter(index(), fn user -> Enum.find(ids, &(&1 == user.id)) != nil end)
  end

  def get_user(id) when is_binary(id) do
    {id, _} = Integer.parse(id)
    List.first(Enum.filter(index(), &(&1.id == id)))
  end

  def get_user(id) do
    List.first(Enum.filter(index(), &(&1.id == id)))
  end

  def index do
    lista = Agent.get(MockTdAuthService, &Map.get(&1, :users)) || []
    lista
  end

  defp list_groups do
    Agent.get(MockTdAuthService, &Map.get(&1, :groups)) || []
  end

  def create_group(%{"group" => %{"name" => name}}) do
    group = %{id: Group.gen_id_from_name(name), name: name}
    groups = list_groups()
    Agent.update(MockTdAuthService, &Map.put(&1, :groups, groups ++ [group]))
    group
  end

  def get_group_by_name(name) do
    list_groups()
    |> Enum.filter(&(&1.name == name))
    |> List.first()
  end

  def index_roles do
    Agent.get(MockTdAuthService, &Map.get(&1, :roles)) || []
  end

  def get_role_by_name(name) do
    index_roles()
    |> Enum.filter(&(&1.name == name))
    |> List.first()
  end

  def find_or_create_role(name) do
    roles = index_roles()

    case Enum.find(roles, &(&1.name == name)) do
      nil ->
        last_id = roles |> Enum.map(& &1.id) |> Enum.max(fn -> 0 end)
        role = %{id: last_id + 1, name: name}
        Agent.update(MockTdAuthService, &Map.put(&1, :roles, [role | roles]))
        role

      role ->
        role
    end
  end

  def get_domain_user_roles(domain_id) do
    domain_ids =
      domain_id
      |> Taxonomies.get_parent_ids(true)

    MockPermissionResolver.get_acl_entries()
    |> Enum.filter(&(&1.resource_type == "domain" && Enum.member?(domain_ids, &1.resource_id)))
    |> Enum.map(&Map.put(&1, :role, get_role_by_id(&1.role_id)))
    |> Enum.map(&Map.put(&1, :users, get_users(&1)))
    |> Enum.group_by(& &1.role.name, & &1.users)
    |> Enum.map(fn {role_name, users} -> %{role_name: role_name, users: Enum.concat(users)} end)
  end

  defp get_role_by_id(id) do
    index_roles()
    |> Enum.find(&(&1.id == id))
  end

  defp get_users(%{principal_type: "group", principal_id: group_id}) do
    index()
    |> Enum.filter(&Enum.member?(&1.gids, group_id))
    |> Enum.map(&Map.take(&1, [:id, :user_name, :full_name]))
  end

  defp get_users(%{principal_type: "user", principal_id: user_id}) do
    [get_user(user_id)]
    |> Enum.map(&Map.take(&1, [:id, :user_name, :full_name]))
  end
end
