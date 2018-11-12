defmodule TdBgWeb.TemplateController do
  require Logger
  use TdBgWeb, :controller
  use PhoenixSwagger

  alias TdBg.Taxonomies
  alias TdBgWeb.SwaggerDefinitions
  alias TdBgWeb.TemplateSupport

  @df_cache Application.get_env(:td_bg, :df_cache)

  action_fallback(TdBgWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.template_swagger_definitions()
  end

  swagger_path :get_domain_templates do
    description("List Domain Templates")

    parameters do
      domain_id(:path, :integer, "Domain ID", required: true)
      preprocess(:query, :boolean, "Apply template preproccessing", required: false)
    end

    response(200, "OK", Schema.ref(:TemplatesResponse))
  end

  def get_domain_templates(conn, %{"domain_id" => domain_id} = params) do
    user = conn.assigns[:current_user]

    domain = Taxonomies.get_domain!(domain_id)
    templates = @df_cache.list_templates()

    templates =
      case Map.get(params, "preprocess", false) do
        "true" ->
          TemplateSupport.preprocess_templates(templates, %{domain: domain, user: user})
        _ ->
          templates
      end

    render(conn, "index.json", templates: templates)
  end

end
