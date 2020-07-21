defmodule TdBg.Repo.Migrations.RemoveDomainNameUniqueConstraint do
  @moduledoc """
  Name field should no longer be an unique index
  """
  use Ecto.Migration

  def change do
    drop(unique_index(:domains, [:name], name: :index_domain_by_name))
  end
end
