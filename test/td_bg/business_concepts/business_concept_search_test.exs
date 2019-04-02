defmodule TdBg.BusinessConceptSearch do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdBgWeb.Authentication, only: :functions

  alias TdBg.BusinessConcept.Search
  alias TdBg.Permissions.MockPermissionResolver
  alias TdBgWeb.ApiServices.MockTdAuditService
  alias TdBgWeb.ApiServices.MockTdAuthService
  alias TdBgWeb.ApiServices.MockTdDdService
  alias TdBgWeb.Authentication

  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Repo
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

    @jwt "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJ0ZGF1dGgiLCJleHAiOjE1NTQyNDM2MzYsImdpZHMiOltdLCJoYXNfcGVybWlzc2lvbnMiOnRydWUsImlhdCI6MTU1NDIwMDQzNiwiaXNfYWRtaW4iOnRydWUsImlzcyI6InRkYXV0aCIsImp0aSI6ImYxYjQ1MmI1LTZmMDMtNDIyOS04ODhkLTI5MTljY2EwMDY2ZCIsIm5iZiI6MTU1NDIwMDQzNSwic3ViIjoie1widXNlcl9uYW1lXCI6XCJkYXZpZC5mZXJuYW5kZXpAYmx1ZXRhYi5uZXRcIixcImlzX2FkbWluXCI6dHJ1ZSxcImlkXCI6NDZ9IiwidHlwIjoiYWNjZXNzIiwidXNlcl9uYW1lIjoiZGF2aWQuZmVybmFuZGV6QGJsdWV0YWIubmV0In0.HcBMx_HPuSO3QxeWMQmI9k18rPu9ommip7e6QdWFWb3G6f0igScR5m6n4lFoerbSJyDVseiPFyuBD2CDUcWFWg"

    defp create_versions do
      template_content = [%{name: "fieldname", type: "string", cardinality: "?"}]

      template =
        create_template(%{id: 0, name: "onefield", content: template_content, label: "label"})

      domain = insert(:domain)
      child = insert(:business_concept, type: template.name, domain: domain)
      parent = insert(:business_concept, type: template.name, domain: domain)

      version1 = insert(:business_concept_version, business_concept: child)
      version2 = insert(:business_concept_version, business_concept: parent)

      version3 = insert(:business_concept_version, business_concept: child)
      version4 = insert(:business_concept_version, business_concept: parent)

      {domain, version1, version2}
    end

    defp acl_entry_fixture(role_name \\ "watch") do
      user = insert(:user)
      role = Role.role_get_or_create_by_name(role_name)

      insert(:acl_entry_resource, principal_id: user.id, resource_id: 1234, role: role)
    end

    test "return list of bc_versions with user admin" do
      {domain, version1, version2} = create_versions()

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
      {domain, version1, version2} = create_versions()

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
