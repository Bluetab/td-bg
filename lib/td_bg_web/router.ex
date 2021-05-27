defmodule TdBgWeb.Router do
  use TdBgWeb, :router

  pipeline :api do
    plug(TdBg.Auth.Pipeline.Unsecure)
    plug(TdBgWeb.Locale)
    plug(:accepts, ["json"])
  end

  pipeline :api_secure do
    plug(TdBg.Auth.Pipeline.Secure)
  end

  pipeline :api_authorized do
    plug(TdBg.Auth.CurrentResource)
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

    resources "/domains", DomainController, except: [:new, :edit] do
      get("/business_concepts/:user_name/count", DomainController, :count_bc_in_domain_for_user)
    end

    resources("/business_concepts/comments", CommentController,
      only: [:create, :delete, :show, :index]
    )

    resources "/business_concepts", BusinessConceptController, only: [] do
      resources("/versions", BusinessConceptVersionController, only: [:show, :index])
      resources("/shared_domains", SharedDomainController, only: [:update], singleton: true)
    end

    post("/business_concept_versions/csv", BusinessConceptVersionController, :csv)
    post("/business_concept_versions/upload", BusinessConceptVersionController, :upload)
    post("/business_concept_versions/bulk_update", BusinessConceptVersionController, :bulk_update)
    put("/business_concept_versions/:id", BusinessConceptVersionController, :update)

    resources "/business_concept_versions", BusinessConceptVersionController,
      except: [:show, :new, :edit, :update] do
      post("/submit", BusinessConceptVersionController, :send_for_approval)
      post("/publish", BusinessConceptVersionController, :publish)
      post("/reject", BusinessConceptVersionController, :reject)
      post("/deprecate", BusinessConceptVersionController, :deprecate)
      post("/version", BusinessConceptVersionController, :version)
      post("/redraft", BusinessConceptVersionController, :undo_rejection)
      post("/set_confidential", BusinessConceptVersionController, :set_confidential)
      resources("/links", BusinessConceptLinkController, only: [:delete])
      post("/links", BusinessConceptLinkController, :create_link)
    end

    post("/business_concept_versions/search", BusinessConceptVersionController, :search)

    get("/business_concept_filters", BusinessConceptFilterController, :index)
    post("/business_concept_filters/search", BusinessConceptFilterController, :search)

    get("/business_concept_user_filters/user/me", UserSearchFilterController, :index_by_user)
    resources("/business_concept_user_filters", UserSearchFilterController, except: [:new, :edit])
    get("/business_concepts/search/reindex_all", SearchController, :reindex_all)
  end

  def swagger_info do
    %{
      schemes: ["http", "https"],
      info: %{
        version: Application.spec(:td_bg, :vsn),
        title: "Truedat Business Glossary Service"
      },
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
