defmodule TdBg.Repo.Migrations.CreateTableI18nContent do
  use Ecto.Migration

  use Ecto.Migration

  def change do
    create table("i18n_contents") do
      add(:lang, :string, null: false)
      add(:name, :string, null: false)
      add(:content, :map)

      add(
        :business_concept_version_id,
        references(:business_concept_versions, on_delete: :delete_all),
        null: false
      )

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:i18n_contents, [:business_concept_version_id, :lang]))
  end
end
