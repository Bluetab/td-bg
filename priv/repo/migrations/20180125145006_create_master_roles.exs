defmodule TrueBG.Repo.Migrations.CreateMasterRoles do
  use Ecto.Migration

  alias TrueBG.Permissions
  alias TrueBG.Permissions.Role

  def change do
    Enum.each ["admin", "watch", "create", "publish"], fn role_name ->
      Permissions.create_role(%{name: role_name})
    end
  end
end
