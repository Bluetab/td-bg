defmodule TdBgWeb.UserController do
  use TdBgWeb, :controller
  use PhoenixSwagger
  alias TdBg.Accounts.User
  alias TdBg.Canada.BusinessConceptAbilities
  alias TdBg.Taxonomies
  alias TdBg.Taxonomies.Domain
  alias TdBgWeb.SwaggerDefinitions
  alias TdBgWeb.UserView

  action_fallback TdBgWeb.FallbackController

  @td_auth_api Application.get_env(:td_bg, :auth_service)[:api_service]

  def create(_conn, %{"user" => _user_params} = req) do
    @td_auth_api.create_user(req)
  end

  def search(_conn, %{"ids" => _ids} = req) do
    @td_auth_api.search_users(req)
  end

  def swagger_definitions do
    SwaggerDefinitions.domain_swagger_definitions()
  end

  swagger_path :user_domains do
    get "/users/permissions/domains"
    description "Lists all the domains for which has a create_business_concept permission"
    produces "application/json"
    response 200, "Ok", Schema.ref(:UserDomainResponse)
  end

  def user_domains(conn, _params) do
    user = conn.assigns[:current_user]
    d_all = Taxonomies.list_domains()
    list_filtered_domains = Enum.filter(d_all,
      fn(domain) ->
        BusinessConceptAbilities.can?(%User{} = user, :create_business_concept,
          %Domain{} = domain)
    end)
    render(conn, UserView, "user_domains.json",
      %{user_domains: list_filtered_domains})
  end

end
