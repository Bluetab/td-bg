defmodule TdBgWeb.ApiServices.MockTdAuthService do
  @moduledoc false

  @users [
    %TdBg.Accounts.User{id: Integer.mod(:binary.decode_unsigned("app-admin"), 100_000), is_admin: true, user_name: "app-admin"},
    %TdBg.Accounts.User{id: 10, is_admin: false, user_name: "watcher"},
    %TdBg.Accounts.User{id: 11, is_admin: false, user_name: "creator"},
    %TdBg.Accounts.User{id: 12, is_admin: false, user_name: "publisher"},
    %TdBg.Accounts.User{id: 13, is_admin: false, user_name: "admin"},
    %TdBg.Accounts.User{id: 14, is_admin: false, user_name: "pietro.alpin"},
    %TdBg.Accounts.User{id: 15, is_admin: false, user_name: "johndoe"},
    %TdBg.Accounts.User{id: 16, is_admin: false, user_name: "Hari.seldon"},
    %TdBg.Accounts.User{id: 17, is_admin: false, user_name: "tomclancy"},
    %TdBg.Accounts.User{id: 18, is_admin: false, user_name: "Peter.sellers"},
    %TdBg.Accounts.User{id: 19, is_admin: false, user_name: "tom.sawyer"}
  ]

  def create(%{"user" => user_params}) do
      Enum.find(@users, fn(user) -> user_params.user_name == user.user_name end)
  end

  def search(%{"data" => %{"ids" => ids}}) do
    Enum.filter(@users, fn(user) -> Enum.find(ids, &(&1 == user.id)) != nil end)
  end
end
