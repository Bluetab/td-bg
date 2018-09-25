defmodule TdBg.Repo.Migrations.AddLabelToTemplate do
  use Ecto.Migration

  def up do
    alter table(:templates), do: add    :label,  :string, null: true
    flush()
    execute("update templates set label = name")
    alter table(:templates), do: modify :label, :string, null: false
    create unique_index(:templates, [:label])
  end

  def down do
    alter table(:templates), do: remove :label
  end
end
