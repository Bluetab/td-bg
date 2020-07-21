defmodule TdBg.Repo.Migrations.AddDefaultTemplate do
  use Ecto.Migration

  def up do
    alter table(:templates) do
      add(:is_default, :boolean, default: false, null: true)
    end

    flush()

    execute("update templates set is_default = false")

    execute(
      "update templates set is_default = true where id in (select id from templates limit 1)"
    )

    alter table(:templates) do
      modify(:is_default, :boolean, default: false, null: false)
    end
  end

  def down do
    alter table(:templates) do
      remove(:is_default)
    end
  end
end
