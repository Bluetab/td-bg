defmodule TdBg.Repo.Migrations.AddOban do
  use Ecto.Migration

  use Ecto.Migration

  def up,
    do:
      Oban.Migration.up(
        prefix: Application.get_env(:td_bg, Oban)[:prefix],
        create_schema: Application.get_env(:td_bg, :create_oban_schema)
      )

  def down,
    do: Oban.Migration.down(prefix: Application.get_env(:td_bg, Oban)[:prefix], version: 1)
end
