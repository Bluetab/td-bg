defmodule TdBg.Repo.Migrations.CreateAclEntries do
  use Ecto.Migration

  def change do
    create table(:acl_entries) do
      add :principal_type, :string
      add :principal_id, :integer
      add :resource_type, :string
      add :resource_id, :integer
      add :role_id, references(:roles, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:acl_entries, [:role_id])
  end
end
