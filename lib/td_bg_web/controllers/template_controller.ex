defmodule TdBgWeb.TemplateController do
  use TdBgWeb, :controller
  use PhoenixSwagger

  alias TdBg.Taxonomies
  alias TdBg.Templates
  alias TdBg.Templates.Template
  alias TdBgWeb.ErrorView
  alias TdBgWeb.SwaggerDefinitions
  alias TdBgWeb.TemplateSupport

  @preprocess "preprocess"

  action_fallback(TdBgWeb.FallbackController)

  def swagger_definitions do
    SwaggerDefinitions.template_swagger_definitions()
  end

  swagger_path :index do
    description("List Templates")
    response(200, "OK", Schema.ref(:TemplatesResponse))
  end

  def index(conn, _params) do
    templates = Templates.list_templates()
    render(conn, "index.json", templates: templates)
  end

  swagger_path :create do
    description("Creates a Template")
    produces("application/json")

    parameters do
      template(:body, Schema.ref(:TemplateCreateUpdate), "Template create attrs")
    end

    response(201, "Created", Schema.ref(:TemplateResponse))
    response(400, "Client Error")
  end

  def create(conn, %{"template" => template}) do
    with false <- is_nil(template["name"]),
         true <- is_nil(Templates.get_template_by_name(template["name"])),
         {:ok, %Template{} = template} <- Templates.create_template(template) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", template_path(conn, :show, template))
      |> render("show.json", template: template)
    else
      false ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: %{name: ["unique"]}})

      _error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  swagger_path :show do
    description("Show Template")
    produces("application/json")

    parameters do
      id(:path, :integer, "Template ID", required: true)
    end

    response(200, "OK", Schema.ref(:TemplateResponse))
    response(400, "Client Error")
  end

  def show(conn, %{"id" => id}) do
    template = Templates.get_template!(id)
    render(conn, "show.json", template: template)
  end

  swagger_path :load_and_show do
    description("Load and show Template")
    produces("application/json")

    parameters do
      id(:path, :integer, "Template ID", required: true)
    end

    response(200, "OK", Schema.ref(:TemplateResponse))
    response(400, "Client Error")
  end

  def load_and_show(conn, %{"id" => id}) do
    {:ok, template} = load_template(Templates.get_template!(id))
    render(conn, "show.json", template: template)
  end

  defp load_template(template) do
    includes =
      List.first(Enum.filter(Map.get(template, :content), fn field -> field["includes"] end))[
        "includes"
      ]

    case includes do
      nil -> {:ok, template}
      _ -> load_template(template, includes)
    end
  end

  defp load_template(template, includes) do
    includes =
      Enum.reduce(includes, [], fn name, acc ->
        case Templates.get_template_by_name(name) do
          nil -> acc
          _ -> [name] ++ acc
        end
      end)

    my_fields = Enum.reject(Map.get(template, :content), fn field -> field["includes"] end)

    case length(includes) do
      0 ->
        {:ok, Map.put(template, :content, my_fields)}

      _ ->
        final_fields =
          my_fields ++
            Enum.reduce(includes, [], fn templ, acc ->
              Map.get(Templates.get_template_by_name(templ), :content) ++ acc
            end)

        {:ok, Map.put(template, :content, final_fields)}
    end
  end

  swagger_path :update do
    description("Updates Template")
    produces("application/json")

    parameters do
      template(:body, Schema.ref(:TemplateCreateUpdate), "Template update attrs")
      id(:path, :integer, "Template ID", required: true)
    end

    response(200, "OK", Schema.ref(:TemplateResponse))
    response(400, "Client Error")
  end

  def update(conn, %{"id" => id, "template" => template_params}) do
    template = Templates.get_template!(id)

    with {:ok, %Template{} = template} <- Templates.update_template(template, template_params) do
      render(conn, "show.json", template: template)
    end
  end

  swagger_path :delete do
    description("Delete Template")
    produces("application/json")

    parameters do
      id(:path, :integer, "Template ID", required: true)
    end

    response(204, "OK")
    response(400, "Client Error")
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
    templates = case Templates.get_domain_templates(domain) do
        [] ->
          case Templates.get_default_template do
            nil -> []
            domain_template -> [domain_template]
          end
        domain_templates -> domain_templates
    end

    templates =
      case Map.get(params, @preprocess, false) do
        "true" ->
          TemplateSupport.preprocess_templates(templates, %{domain: domain, user: user})

        _ ->
          templates
      end

    render(conn, "index.json", templates: templates)
  end

  swagger_path :add_templates_to_domain do
    description("Add Templates to Domain")

    parameters do
      domain_id(:path, :integer, "Domain ID", required: true)
      templates(:body, Schema.ref(:AddTemplatesToDomain), "Add Templates to Domain attrs")
    end

    response(200, "OK", Schema.ref(:TemplatesResponse))
  end

  def add_templates_to_domain(conn, %{"domain_id" => domain_id, "templates" => templ}) do
    domain = Taxonomies.get_domain!(domain_id)
    templates = Enum.map(templ, &Templates.get_template_by_name(Map.get(&1, "name")))
    Templates.add_templates_to_domain(domain, templates)
    render(conn, "index.json", templates: templates)
  end
end
