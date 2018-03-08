defmodule TdBGWeb.Router do
  use TdBGWeb, :router

  pipeline :api do
    plug TdBG.Auth.Pipeline.Unsecure
    plug :accepts, ["json"]
  end

  pipeline :api_secure do
    plug TdBG.Auth.Pipeline.Secure
  end

  pipeline :api_authorized do
    plug TdBG.Permissions.Plug.CurrentUser
    plug Guardian.Plug.LoadResource
  end

  scope "/api", TdBGWeb do
    pipe_through :api
    get  "/ping", PingController, :ping
    post "/echo", EchoController, :echo
  end

  scope "/api", TdBGWeb do
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

  scope "/api", TdBGWeb do
    pipe_through [:api, :api_secure, :api_authorized]
    resources "/data_domains", DataDomainController, except: [:new, :edit, :create]
    get "/domain_groups/index_root", DomainGroupController, :index_root
    resources "/domain_groups", DomainGroupController, except: [:new, :edit] do
      get "/index_children", DomainGroupController, :index_children
      get "/data_domains", DataDomainController, :index_children_data_domain
      post "/data_domain", DataDomainController, :create
    end
    resources "/data_domains", DataDomainController do
      post "/business_concept", BusinessConceptController, :create
      get "/business_concepts", BusinessConceptController, :index_children_business_concept
      post "/users_roles", DataDomainController, :users_roles
    end

    resources "/business_concepts", BusinessConceptController, except: [:new, :edit]
    resources "/business_concepts", BusinessConceptController do
      patch "/status", BusinessConceptController, :update_status
    end

    resources "/business_concept_versions", BusinessConceptVersionController, except: [:new, :edit, :create, :update, :delete]

    resources "/business_concepts", BusinessConceptController do
      post "/versions", BusinessConceptVersionController, :create
    end

  end

  def swagger_info do
    %{
      schemes: ["http"],
      info: %{
        version: "1.0",
        title: "TdBG"
      },
      "basePath": "/api",
      "securityDefinitions":
        %{
          bearer:
          %{
            "type": "apiKey",
            "name": "Authorization",
            "in": "header",
          }
      },
      "security": [
        %{
         bearer: []
        }
      ]
    }
  end

end
