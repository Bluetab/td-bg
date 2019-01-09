defmodule TdBg.Repo.Migrations.DropObsoleteTables do
  use Ecto.Migration

  def change do
    # roles_permissions
    drop unique_index(:roles_permissions, [:role_id, :permission_id])
    drop table("roles_permissions")

    # permissions
    drop unique_index(:permissions, [:name])
    drop table("permissions")

    # acl_entries
    drop index(:acl_entries, [:role_id])
    drop table("acl_entries")

    # roles
    drop table("roles")
  end

end
