defmodule TdBg.Mixfile do
  use Mix.Project

  def project do
    [
      app: :td_bg,
      version:
        case System.get_env("APP_VERSION") do
          nil -> "7.0.0-local"
          v -> v
        end,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        td_bg: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent],
          steps: [:assemble, &copy_bin_files/1, :tar]
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {TdBg.Application, []},
      extra_applications: [:logger, :runtime_tools, :td_cache, :td_core]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp copy_bin_files(release) do
    File.cp_r("rel/bin", Path.join(release.path, "bin"))
    release
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.18"},
      {:phoenix_ecto, "~> 4.6.3"},
      {:plug_cowboy, "~> 2.7"},
      {:ecto_sql, "~> 3.12.1"},
      {:postgrex, "~> 0.19.3"},
      {:jason, "~> 1.4.4"},
      {:guardian, "~> 2.3.2"},
      {:canada, "~> 2.0"},
      {:corsica, "~> 2.1.3"},
      {:quantum, "~> 3.5.3"},
      {:csv, "~> 3.2.1"},
      {:nimble_csv, "~> 1.2"},
      {:elixlsx, "~> 0.6"},
      {:xlsx_reader, "~> 0.8.7"},
      {:codepagex, "~> 0.1.9"},
      {:td_hypermedia, git: "https://github.com/Bluetab/td-hypermedia.git", tag: "7.0.0"},
      {:td_core, git: "https://github.com/Bluetab/td-core.git", tag: "7.1.1"},
      {:credo, "~> 1.7.11", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4.5", only: :dev, runtime: false},
      {:ex_machina, "~> 2.8", only: :test},
      {:assertions, "~> 0.20.1", only: :test},
      {:mox, "~> 1.2", only: :test},
      {:sobelow, "~> 0.13", only: [:dev, :test]}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "run priv/repo/seeds.exs", "test"]
    ]
  end
end
