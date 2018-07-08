defmodule TdBgWeb.ApiServices.MockTdAuthService do
  @moduledoc false

  use Agent

  alias TdBg.Accounts.Group
  alias TdBg.Accounts.User

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

  def index_groups do
    Agent.get(MockTdAuthService, &Map.get(&1, :groups)) || []
  end

  def create_group(%{"group" => %{"name" => name}}) do
    group = %{id: Group.gen_id_from_name(name), name: name}
    groups = index_groups()
    Agent.update(MockTdAuthService, &Map.put(&1, :groups, groups ++ [group]))
    group
  end

  def get_group_by_name(name) do
    index_groups()
    |> Enum.filter(&(&1.name == name))
    |> List.first()
  end

  def search_groups(%{"ids" => ids}) do
    Enum.filter(index_groups(), fn group -> Enum.find(ids, &(&1 == group.id)) != nil end)
  end

  def search_groups_by_user_id(id) do
    user = get_user(id)
    user.groups
  end

  def get_groups_users(group_ids, extra_user_ids \\ [])

  def get_groups_users(group_ids, extra_user_ids) do
    accumulate_if_user_in_groups = fn user, acc, group_ids ->
      case Enum.find(user.groups, &Enum.member?(group_ids, Group.gen_id_from_name(&1))) do
        nil -> acc
        _ -> [user | acc]
      end
    end

    users = index()

    Enum.reduce(users, [], fn user, acc ->
      case Enum.member?(extra_user_ids, user.id) do
        true -> [user | acc]
        false -> accumulate_if_user_in_groups.(user, acc, group_ids)
      end
    end)
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

  def get_domain_user_roles(_domain_id) do
    [] # TODO: Implement this...
  end
end
