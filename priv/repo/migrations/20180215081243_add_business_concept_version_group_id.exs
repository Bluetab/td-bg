defmodule TrueBG.Repo.Migrations.AddBusinessConceptVersionGroupId do
  use Ecto.Migration

  def change do
      alter table(:business_concepts) do
        remove :last_version_id
        add    :version_group_id, :uuid, null: false
      end
  end
end
