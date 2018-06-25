defmodule TdBg.Accounts.User do
  @moduledoc false

  @td_auth_api Application.get_env(:td_bg, :auth_service)[:api_service]

  defstruct id: 0,
            user_name: nil,
            password: nil,
            is_admin: false,
            email: nil,
            full_name: nil,
            gids: [],
            groups: [],
            jti: nil

  def gen_id_from_user_name(user_name) do
    Integer.mod(:binary.decode_unsigned(user_name), 100_000)
  end

  def get_group_ids(user) do
    @td_auth_api.index_groups()
    |> Enum.filter(fn group ->
      Enum.any?(user.groups, fn group_name -> group_name == group.name end)
    end)
    |> Enum.map(& &1.id)
  end

end
