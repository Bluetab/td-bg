defmodule TdBg.Repo.Migrations.CreateRolesPermissions do
  use Ecto.Migration

  def change do
    create table(:roles_permissions) do
      add(:role_id, references(:roles))
      add(:permission_id, references(:permissions))
    end

    create(unique_index(:roles_permissions, [:role_id, :permission_id]))
  end
end
