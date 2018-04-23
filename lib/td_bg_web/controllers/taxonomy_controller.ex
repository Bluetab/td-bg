defmodule TdBgWeb.TaxonomyController do
  use TdBgWeb, :controller
  use PhoenixSwagger

  alias TdBg.Taxonomies
  alias TdBg.Permissions
  alias TdBg.Taxonomies.Domain
  alias TdBgWeb.SwaggerDefinitions

  action_fallback TdBgWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.taxonomy_swagger_definitions()
  end

  swagger_path :tree do
    get "/taxonomy/tree"
    description "Returns tree of Domains"
    produces "application/json"
    response 200, "Ok", Schema.ref(:TaxonomyTreeResponse)
    response 400, "Client error"
  end
  def tree(conn, _params) do
    tree = Taxonomies.tree
    tree_output = tree |> format_tree
    json conn, %{"data": tree_output}
  end

  defp format_tree(nil), do: nil

  defp format_tree(tree) do
    Enum.map(tree, fn(node) ->
      build_node(node)
    end)
  end

  defp build_node(domain) do
    domain_map = build_map(domain)
    Map.merge(domain_map, %{children: format_tree(domain.children)})
  end

  defp build_map(%Domain{} = domain) do
    %{id: domain.id, name: domain.name, description: domain.description, children: []}
  end

  swagger_path :roles do
    get "/taxonomy/roles?principal_id={principal_id}"
    description "Returns tree of Domains"
    produces "application/json"
    parameters do
      principal_id :path, :integer, "user id", required: true
    end
    response 200, "Ok" , Schema.ref(:TaxonomyRolesResponse)
    response 400, "Client error"
  end
  def roles(conn, %{"principal_id" => principal_id}) do
    taxonomy_roles = Permissions.assemble_roles(%{user_id: principal_id})
    all_roles = Permissions.list_roles()
    taxonomy_roles = Enum.map(taxonomy_roles, &(%{id: &1.id, role: &1.role, role_id: find_role_by_name(all_roles, &1.role).id, acl_entry_id: &1.acl_entry_id, inherited: &1.inherited}))

    roles_domain = case taxonomy_roles do
      nil -> %{}
      tr -> tr |> Enum.reduce(%{}, fn(x, acc) -> Map.put(acc, x.id, %{role: x.role, role_id: x.role_id, acl_entry_id: x.acl_entry_id, inherited: x.inherited}) end)
    end

    taxonomy_roles = %{"domains": roles_domain}
    json conn, %{"data": taxonomy_roles}
  end
  def roles(conn, _params), do: json conn, %{"data": []}

  defp find_role_by_name(roles, role_name) do
    Enum.find(roles, fn(role) -> role.name == role_name end)
  end
end
