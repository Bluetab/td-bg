defmodule TdBg.Repo do
  use Ecto.Repo,
    otp_app: :td_bg,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  end

  def whereis(opts \\ []) do
    case Process.whereis(TdBg.Repo) do
      nil ->
        case Keyword.get(opts, :timeout, 1_000) do
          x when x < 0 ->
            {:error, :timeout}

          millis ->
            Process.sleep(100)
            whereis(timeout: millis - 100)
        end

      pid ->
        {:ok, pid}
    end
  end
end
