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
    get  "/ping", PingController, :ping
    post "/echo", EchoController, :echo
  end

  scope "/api", TrueBGWeb do
    pipe_through [:api, :api_secure]
    resources "/users", UserController, except: [:new, :edit]
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
    resources "/data_domains", DataDomainController, except: [:new, :edit, :create]
    get "/domain_groups/index_root", DomainGroupController, :index_root
    resources "/domain_groups", DomainGroupController, except: [:new, :edit] do
      get "/index_children", DomainGroupController, :index_children
      get "/data_domains", DataDomainController, :index_children_data_domain
      post "/data_domain", DataDomainController, :create
    end
    get "/business_concepts/:id/index_children", BusinessConceptController, :index_children_business_concept
    resources "/data_domains", DataDomainController do
      post "/business_concept", BusinessConceptController, :create
    end
    put "/business_concepts/:id/send_por_approval", BusinessConceptController, :send_for_approval
    put "/business_concepts/:id/reject", BusinessConceptController, :reject
    put "/business_concepts/:id/publish", BusinessConceptController, :publish
    resources "/business_concepts", BusinessConceptController, except: [:new, :edit]
  end

end
