defmodule TdBg.Repo.Migrations.UpdateBusinessConceptVersionsTrimName do
  use Ecto.Migration

  import Ecto.Query

  alias TdBg.Repo

  def up do
    from(
      v in "business_concept_versions",
      update: [set: [name: fragment("TRIM(?)", v.name)]],
      where: v.name != fragment("TRIM(?)", v.name)
    )
    |> Repo.update_all([])
  end

  def down do
  end
end
