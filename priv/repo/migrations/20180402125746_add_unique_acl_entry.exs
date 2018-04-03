defmodule TdBg.Repo.Migrations.AddUniqueAclEntry do
  use Ecto.Migration

  def change do
    create unique_index(:acl_entries, [:principal_type, :principal_id, :resource_type, :resource_id], name: :principal_resource_index)
  end
end
