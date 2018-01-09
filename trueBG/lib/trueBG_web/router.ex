defmodule TrueBGWeb.Router do
  use TrueBGWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", TrueBGWeb do
    pipe_through :api
  end
end
