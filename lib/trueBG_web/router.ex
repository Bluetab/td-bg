defmodule TrueBGWeb.Router do
  use TrueBGWeb, :router

  pipeline :api do
    plug TrueBG.Auth.Pipeline.Unsecure
    plug :accepts, ["json"]
  end

  pipeline :api_secure do
    plug TrueBG.Auth.Pipeline.Secure
  end

  pipeline :api_authorized do
    plug TrueBG.Permissions.Plug.CurrentUser
    plug Guardian.Plug.LoadResource
  end

  scope "/api", TrueBGWeb do
    pipe_through :api
    get "/ping", PingController, :ping
    post "/sessions", SessionController, :create
  end

  scope "/api", TrueBGWeb do
    pipe_through [:api, :api_secure]
    get "/sessions", SessionController, :ping
    delete "/sessions", SessionController, :destroy
    put "/sessions", SessionController, :change_password
    resources "/users", UserController, except: [:new, :edit]
    resources "/business_concepts", BusinessConceptController, except: [:new, :edit]
    resources "/roles", RoleController, except: [:new, :edit]
    resources "/acl_entries", AclEntryController, except: [:new, :edit]

    resources "/users", UserController do
      resources "/domain_groups", DomainGroupController do
        get "/roles", RoleController, :user_domain_group_role
      end
      resources "/data_domains", DataDomainController do
        get "/roles", RoleController, :user_data_domain_role
      end
    end
  end

  scope "/api", TrueBGWeb do
    pipe_through [:api, :api_secure, :api_authorized]
    resources "/domain_groups", DomainGroupController, except: [:new, :edit]
    resources "/data_domains", DataDomainController, except: [:new, :edit]
  end

end
