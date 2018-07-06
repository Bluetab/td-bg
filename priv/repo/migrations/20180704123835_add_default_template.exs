defmodule TdBg.Repo.Migrations.AddDefaultTemplate do
  use Ecto.Migration
  import Ecto.Query
  alias TdBg.Repo
  alias TdBg.Templates.Template

  def up do
    alter table(:templates) do
      add :is_default, :boolean, default: false, null: true
    end

    flush()

    Repo.update_all(Template, set: [is_default: false])

    case Repo.one from(Template, limit: 1) do
      nil -> nil
      template ->
        id = template.id
        from(t in Template, where: t.id == ^id)
        |> Repo.update_all(set: [is_default: true])
    end

    alter table(:templates) do
      modify :is_default, :boolean, default: false, null: false
    end
  end

  def down do
    alter table(:templates) do
      remove :is_default
    end
  end
end
