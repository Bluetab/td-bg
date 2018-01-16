defmodule TrueBGWeb.Router do
  use TrueBGWeb, :router

  pipeline :api do
    plug TrueBG.GuardianPipeline
    # plug Guardian.Plug.VerifyHeader
    # plug Guardian.Plug.LoadResource

    plug :accepts, ["json"]
  end

  scope "/api", TrueBGWeb do
    pipe_through :api
    get "/ping", PingController, :ping
    resources "/users", UserController, except: [:new, :edit]
    post "/sessions", SessionController, :create
  end
end
