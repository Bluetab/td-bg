defmodule TdBgWeb.Router do
  use TdBgWeb, :router

  @endpoint_url "#{Application.get_env(:td_bg, TdBgWeb.Endpoint)[:url][:host]}:#{
                  Application.get_env(:td_bg, TdBgWeb.Endpoint)[:url][:port]
                }"

  pipeline :api do
    plug(TdBg.Auth.Pipeline.Unsecure)
    plug(TdBgWeb.Locale)
    plug(:accepts, ["json"])
  end

  pipeline :api_secure do
    plug(TdBg.Auth.Pipeline.Secure)
  end

  pipeline :api_authorized do
    plug(TdBg.Auth.CurrentUser)
    plug(Guardian.Plug.LoadResource)
  end

  scope "/api/swagger" do
    forward("/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :td_bg, swagger_file: "swagger.json")
  end

  scope "/api", TdBgWeb do
    pipe_through(:api)
    get("/ping", PingController, :ping)
    post("/echo", EchoController, :echo)
  end

  scope "/api", TdBgWeb do
    pipe_through([:api, :api_secure, :api_authorized])
    options("/domains", DomainController, :options)

    resources "/domains", DomainController, except: [:new, :edit] do
      get("/business_concepts/:user_name/count", DomainController, :count_bc_in_domain_for_user)
    end

    post("/business_concept_versions/csv", BusinessConceptVersionController, :csv)
    post("/business_concept_versions/upload", BusinessConceptVersionController, :upload)
    post("/business_concept_versions/bulk_update", BusinessConceptVersionController, :bulk_update)
    put("/business_concept_versions/:id", BusinessConceptVersionController, :update)

    resources "/business_concept_versions", BusinessConceptVersionController,
      except: [:new, :edit, :update] do
      post("/submit", BusinessConceptVersionController, :send_for_approval)
      post("/publish", BusinessConceptVersionController, :publish)
      post("/reject", BusinessConceptVersionController, :reject)
      post("/deprecate", BusinessConceptVersionController, :deprecate)
      post("/version", BusinessConceptVersionController, :version)
      post("/redraft", BusinessConceptVersionController, :undo_rejection)
      get("/data_structures", BusinessConceptVersionController, :get_data_structures)

      get("/versions", BusinessConceptVersionController, :versions)
      resources("/links", LinkController, only: [:delete])
      post("/links", LinkController, :create_link)
    end

    post("/business_concept_versions/search", BusinessConceptVersionController, :search)

    get("/business_concept_filters", BusinessConceptFilterController, :index)
    post("/business_concept_filters/search", BusinessConceptFilterController, :search)

    resources("/business_concepts/comments", CommentController, except: [:new, :edit])

    get("/business_concepts/search/reindex_all", SearchController, :reindex_all)
  end

  def swagger_info do
    %{
      schemes: ["http"],
      info: %{
        version: "1.0",
        title: "TdBg"
      },
      host: @endpoint_url,
      # basePath: "/api",
      securityDefinitions: %{
        bearer: %{
          type: "apiKey",
          name: "Authorization",
          in: "header"
        }
      },
      security: [
        %{
          bearer: []
        }
      ]
    }
  end
end
