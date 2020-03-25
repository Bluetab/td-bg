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
    Agent.get(MockTdAuthService, &Map.get(&1, :users)) || []
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
end
