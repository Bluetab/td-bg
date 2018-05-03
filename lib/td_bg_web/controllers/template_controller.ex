defmodule TdBgWeb.TemplateController do
  use TdBgWeb, :controller
  use PhoenixSwagger

  alias TdBg.Templates
  alias TdBg.Templates.Template
  alias TdBgWeb.SwaggerDefinitions
  alias TdBg.Taxonomies
  alias TdBgWeb.ErrorView

  action_fallback TdBgWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.template_swagger_definitions()
  end

  swagger_path :index do
    get "/templates"
    description "List Templates"
    response 200, "OK", Schema.ref(:TemplatesResponse)
  end
  def index(conn, _params) do
    templates = Templates.list_templates()
    render(conn, "index.json", templates: templates)
  end

  swagger_path :create do
    post "/templates"
    description "Creates a Template"
    produces "application/json"
    parameters do
      template :body, Schema.ref(:TemplateCreateUpdate), "Template create attrs"
    end
    response 201, "Created", Schema.ref(:TemplateResponse)
    response 400, "Client Error"
  end
  def create(conn, %{"template" => template_params}) do
    with {:ok, %Template{} = template} <- Templates.create_template(template_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", template_path(conn, :show, template))
      |> render("show.json", template: template)
    end
  end

  swagger_path :show do
    get "/templates/{id}"
    description "Show Template"
    produces "application/json"
    parameters do
      id :path, :integer, "Template ID", required: true
    end
    response 200, "OK", Schema.ref(:TemplateResponse)
    response 400, "Client Error"
  end
  def show(conn, %{"id" => id}) do
    template = Templates.get_template!(id)
    render(conn, "show.json", template: template)
  end

  swagger_path :update do
    put "/templates/{id}"
    description "Updates Template"
    produces "application/json"
    parameters do
      template :body, Schema.ref(:TemplateCreateUpdate), "Template update attrs"
      id :path, :integer, "Template ID", required: true
    end
    response 200, "OK", Schema.ref(:TemplateResponse)
    response 400, "Client Error"
  end
  def update(conn, %{"id" => id, "template" => template_params}) do
    template = Templates.get_template!(id)

    with {:ok, %Template{} = template} <- Templates.update_template(template, template_params) do
      render(conn, "show.json", template: template)
    end
  end

  swagger_path :delete do
    delete "/templates/{id}"
    description "Delete Template"
    produces "application/json"
    parameters do
      id :path, :integer, "Template ID", required: true
    end
    response 204, "OK"
    response 400, "Client Error"
  end
  def delete(conn, %{"id" => id}) do
    template = Templates.get_template!(id)
    with {:count, :domain, 0} <- Templates.count_related_domains(String.to_integer(id)),
         {:ok, %Template{}} <- Templates.delete_template(template) do
      send_resp(conn, :no_content, "")
    else
      _error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :get_domain_templates do
    get "/domains/{domain_id}/templates"
    description "List Domain Templates"
    parameters do
      domain_id :path, :integer, "Domain ID", required: true
    end
    response 200, "OK", Schema.ref(:TemplatesResponse)
  end
  def get_domain_templates(conn, %{"domain_id" => domain_id}) do
    domain = Taxonomies.get_domain!(domain_id)
    templates = Templates.get_domain_templates(domain)
    render(conn, "index.json", templates: templates)
  end

  swagger_path :add_templates_to_domain do
    post "/domains/{domain_id}/templates"
    description "Add Templates to Domain"
    parameters do
      domain_id :path, :integer, "Domain ID", required: true
      templates :body, Schema.ref(:AddTemplatesToDomain), "Add Templates to Domain attrs"
    end
    response 200, "OK", Schema.ref(:TemplatesResponse)
  end
  def add_templates_to_domain(conn, %{"domain_id" => domain_id, "templates" => templ}) do
    domain = Taxonomies.get_domain!(domain_id)
    templates = Enum.map(templ, &Templates.get_template_by_name(Map.get(&1, "name")))
    Templates.add_templates_to_domain(domain, templates)
    render(conn, "index.json", templates: templates)
  end
end
