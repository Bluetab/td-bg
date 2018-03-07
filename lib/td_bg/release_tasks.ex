defmodule TdBG.ReleaseTasks do
  @moduledoc false
  alias Ecto.Migrator
  alias TdBG.Repo

  @start_apps [
      :postgrex,
      :ecto
    ]

    @myapps [
      :td_bg
    ]

    @repos [
      Repo
    ]

    def seed do
      #IO.puts "Loading TdBG.."
      # Load the code for TdBG, but don't start it
      :ok = Application.load(:td_bg)

      #IO.puts "Starting dependencies.."
      # Start apps necessary for executing migrations
      Enum.each(@start_apps, &Application.ensure_all_started/1)

      # Start the Repo(s) for TdBG
      #IO.puts "Starting repos.."
      Enum.each(@repos, &(&1.start_link(pool_size: 1)))

      # Run migrations
      Enum.each(@myapps, &run_migrations_for/1)

      # Run the seed script if it exists
      seed_script = Path.join([priv_dir(:td_bg), "repo", "seeds.exs"])
      if File.exists?(seed_script) do
        IO.puts "Running seed script.."
        Code.eval_file(seed_script)
      end

      # Signal shutdown
      #IO.puts "Success!"
      :init.stop()
    end

    def priv_dir(app), do: "#{:code.priv_dir(app)}"

    defp run_migrations_for(app) do
      IO.puts "Running migrations for #{app}"
      Migrator.run(TdBG.Repo, migrations_path(app), :up, all: true)
    end

    defp migrations_path(app), do: Path.join([priv_dir(app), "repo", "migrations"])
    #defp seed_path(app), do: Path.join([priv_dir(app), "repo", "seeds.exs"])
end
