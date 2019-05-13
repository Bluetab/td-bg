defmodule TdBg.Repo.Migrations.AddNewFieldDeletedAtInDomains do
  @moduledoc """
  New field deleted_at is added in order to implement soft deletion
  """
  use Ecto.Migration

  def up do
    alter(table(:domains), do: add(:deleted_at, :utc_datetime_usec))
  end

  def down do
    alter(table(:domains), do: remove(:deleted_at))
  end
end
