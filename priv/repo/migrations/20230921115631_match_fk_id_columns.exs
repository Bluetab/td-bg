defmodule TdBg.Repo.Migrations.MatchFkIdColumns do
  use Ecto.Migration

  def up do
    alter table(:comments) do
      modify(:resource_id, :bigint)
    end

    alter table(:user_search_filters) do
      modify(:user_id, :bigint)
    end
  end

  def down do
    alter table(:comments) do
      modify(:resource_id, :int)
    end

    alter table(:user_search_filters) do
      modify(:user_id, :int)
    end
  end
end
