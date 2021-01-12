defmodule TdBgWeb.ApiServices.MockTdAuthService do
  @moduledoc false

  use Agent

  alias TdBg.Accounts.Session

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: MockTdAuthService)
  end

  def create_session(%{
        "user" => %{
          "user_name" => user_name,
          "role" => role
        }
      }) do
    new_session = %Session{
      user_id: Integer.mod(:binary.decode_unsigned(user_name), 100_000),
      user_name: user_name,
      role: role
    }

    users = index()
    Agent.update(MockTdAuthService, &Map.put(&1, :users, users ++ [new_session]))
    new_session
  end

  def get_user_by_name(user_name) do
    index()
    |> Enum.find(&(&1.user_name == user_name))
  end

  def index do
    Agent.get(MockTdAuthService, &Map.get(&1, :users)) || []
  end
end
