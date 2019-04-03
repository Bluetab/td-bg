defmodule TdBg.BusinessConceptSearch do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  alias TdBg.BusinessConcept.Search
  alias TdBg.Permissions.MockPermissionResolver
  alias TdBgWeb.ApiServices.MockTdAuditService
  alias TdBgWeb.ApiServices.MockTdAuthService
  alias TdBgWeb.ApiServices.MockTdDdService

  @df_cache Application.get_env(:td_bg, :df_cache)

  setup_all do
    start_supervised(MockTdAuthService)
    start_supervised(MockTdAuditService)
    start_supervised(MockTdDdService)
    start_supervised(MockPermissionResolver)
    start_supervised(@df_cache)
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "business_concepts_search" do
    @admin %TdBg.Accounts.User{
      email: nil,
      full_name: nil,
      gids: [1],
      groups: [],
      id: 3,
      is_admin: true,
      jti: "c63a60a1-4ca7-4eba-a2b8-7c3ac71a422f",
      password: nil,
      user_name: "app-admin"
    }

    @not_admin %TdBg.Accounts.User{
      email: nil,
      full_name: nil,
      gids: [1],
      groups: [],
      id: 3,
      is_admin: false,
      jti: "",
      password: nil,
      user_name: "app-admin"
    }

    @page 0
    @size 5

    defp create_versions do
      template_content = [%{name: "fieldname", type: "string", cardinality: "?"}]

      template =
        create_template(%{id: 0, name: "onefield", content: template_content, label: "label"})

      domain = insert(:domain)
      child = insert(:business_concept, type: template.name, domain: domain)
      parent = insert(:business_concept, type: template.name, domain: domain)

      version1 = insert(:business_concept_version, business_concept: child)
      version2 = insert(:business_concept_version, business_concept: parent)

      insert(:business_concept_version, business_concept: child)
      insert(:business_concept_version, business_concept: parent)

      {domain, version1, version2}
    end

    test "return list of bc_versions with user admin" do
      {_, _, version2} = create_versions()

      params = %{
        "filters" => %{
          "id" => version2.id,
          "status" => ["published", "pending_approval", "draft", "rejected"]
        }
      }

      search = Search.search_business_concept_versions(params, @admin, @page, @size)

      assert Map.get(search, :total) == 1
    end

    test "return list of bc_versions with user not admin" do
      {_, _, version2} = create_versions()

      params = %{
        "filters" => %{
          "id" => version2.id,
          "status" => ["published", "pending_approval", "draft", "rejected"]
        }
      }

      search = Search.search_business_concept_versions(params, @not_admin, @page, @size)
      assert Map.get(search, :total) == 0
    end
  end
  def create_template(template) do
    @df_cache.put_template(template)
    template
  end
end
