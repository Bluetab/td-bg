defmodule TdBg.Repo.Migrations.ModifyDomainsDescriptionToText do
  use Ecto.Migration

  def change do
    alter table(:domains) do
      modify(:description, :text, from: :string)
    end
  end
end
