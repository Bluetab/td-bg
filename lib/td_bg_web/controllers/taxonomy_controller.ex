defmodule TdBgWeb.TaxonomyController do
  use TdBgWeb, :controller
  use PhoenixSwagger

  alias TdBg.Taxonomies
  alias TdBg.Permissions
  alias TdBg.Taxonomies.DomainGroup
  alias TdBg.Taxonomies.DataDomain
  alias TdBgWeb.SwaggerDefinitions

  action_fallback TdBgWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.taxonomy_swagger_definitions()
  end

  swagger_path :tree do
    get "/taxonomy/tree"
    description "Returns tree of DGs and DDs"
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

  defp build_node(dg) do
    dg_map = build_map(dg)
    Map.merge(dg_map, %{children: format_tree(dg.children)})
  end

  defp build_map(%DomainGroup{} = dg) do
    %{id: dg.id, name: dg.name, description: dg.description, type: "DG", children: []}
  end

  defp build_map(%DataDomain{} = dd) do
    %{id: dd.id, name: dd.name, description: dd.description, type: "DD", children: []}
  end

  swagger_path :roles do
    get "/taxonomy/roles?principal_id={principal_id}"
    description "Returns tree of DGs and DDs"
    produces "application/json"
    parameters do
      principal_id :path, :integer, "user id", required: true
    end
    response 200, "Ok" , Schema.ref(:TaxonomyRolesResponse)
    response 400, "Client error"
  end
  def roles(conn, params) do
    roles = Permissions.assemble_roles(%{user_id: params["principal_id"]})
    #transform to front expected format
    roles = Enum.group_by(roles, &(&1.type), &(%{id: &1.id, role: &1.role, inherited: &1.inherited}))
    roles_dg = roles["DG"]
    roles_dg = case roles_dg do
      nil -> []
      _ -> roles_dg
    end
    roles_dd = roles["DD"]
    roles_dd = case roles_dd do
      nil -> []
      _ -> roles_dd
    end
    roles = %{"DG": roles_dg, "DD": roles_dd}
    json conn, %{"data": roles}
  end

end
