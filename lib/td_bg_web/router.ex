defmodule TdBgWeb.Router do
  use TdBgWeb, :router

  @endpoint_url "#{Application.get_env(:td_bg, TdBgWeb.Endpoint)[:url][:host]}:#{Application.get_env(:td_bg, TdBgWeb.Endpoint)[:url][:port]}"

  pipeline :api do
    plug TdBg.Auth.Pipeline.Unsecure
    plug :accepts, ["json"]
  end

  pipeline :api_secure do
    plug TdBg.Auth.Pipeline.Secure
  end

  pipeline :api_authorized do
    plug TdBg.Permissions.Plug.CurrentUser
    plug Guardian.Plug.LoadResource
  end

  scope "/api/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :td_bg, swagger_file: "swagger.json"
  end

  scope "/api", TdBgWeb do
    pipe_through :api
    get  "/ping", PingController, :ping
    post "/echo", EchoController, :echo
  end

  scope "/api", TdBgWeb do
    pipe_through [:api, :api_secure]
    resources "/roles", RoleController, except: [:new, :edit]
    resources "/acl_entries", AclEntryController, except: [:new, :edit]

    resources "/users", UserController, except: [:new, :edit] do
      resources "/domain_groups", DomainGroupController do
        get "/roles", RoleController, :user_domain_group_role
      end
      resources "/data_domains", DataDomainController do
        get "/roles", RoleController, :user_data_domain_role
      end
    end
  end

  scope "/api", TdBgWeb do
    pipe_through [:api, :api_secure, :api_authorized]
    get "/domain_groups/index_root", DomainGroupController, :index_root
    resources "/domain_groups", DomainGroupController, except: [:new, :edit] do
      get "/index_children", DomainGroupController, :index_children
      get "/data_domains", DataDomainController, :index_children_data_domain
      post "/data_domain", DataDomainController, :create
      get "/available_users", DomainGroupController, :available_users
      get "/users_roles", DomainGroupController, :users_roles
    end

    resources "/data_domains", DataDomainController, except: [:new, :edit] do
      post "/business_concept", BusinessConceptController, :create
      get "/business_concepts", BusinessConceptController, :index_children_business_concept
      get "/users_roles", DataDomainController, :users_roles
      get "/available_users", DataDomainController, :available_users
    end

    get "/taxonomy/tree", TaxonomyController, :tree
    get "/taxonomy/roles", TaxonomyController, :roles

    resources "/business_concept_versions", BusinessConceptVersionController, except: [:new, :edit, :create, :update, :delete]

    resources "/business_concepts", BusinessConceptController, except: [:new, :edit] do
      get  "/aliases", BusinessConceptAliasController, :index
      post "/aliases", BusinessConceptAliasController, :create
      patch "/status", BusinessConceptController, :update_status
      get "/versions", BusinessConceptVersionController, :versions
      post "/versions", BusinessConceptVersionController, :create
    end

    resources "/business_concept_aliases", BusinessConceptAliasController, except: [:new, :edit, :index, :create, :update]

    post "/search/:search_id", SearchController, :search
  end

  def swagger_info do
    %{
      schemes: ["http"],
      info: %{
        version: "1.0",
        title: "TdBg"
      },
      "host": @endpoint_url,
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
