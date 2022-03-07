defmodule TdBgWeb.BusinessConceptFilterControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import Mox

  alias TdBg.ElasticsearchMock

  setup_all do
    start_supervised!(TdBg.Search.Cluster)
    :ok
  end

  setup :verify_on_exit!

  setup %{conn: conn} do
    insert(:business_concept_version, content: %{"foo" => "bar"}, name: "Concept Name")
    [conn: put_req_header(conn, "accept", "application/json")]
  end

  describe "index" do
    @tag authentication: [role: "admin"]
    test "lists all filters (admin user)", %{conn: conn} do
      ElasticsearchMock
      |> expect(:request, fn
        _, :post, "/concepts/_search", %{aggs: _, size: 0, query: query}, [] ->
          assert %{bool: %{filter: %{match_all: %{}}}} = query
          aggs_response()
      end)

      assert %{"data" => data} =
               conn
               |> get(Routes.business_concept_filter_path(conn, :index))
               |> json_response(:ok)

      assert data == %{"foo" => ["bar", "baz"]}
    end

    @tag authentication: [user_name: "not_an_admin"]
    test "lists all filters (non-admin user)", %{claims: claims, conn: conn} do
      %{id: domain_id} = CacheHelpers.insert_domain()
      put_session_permissions(claims, %{"view_published_business_concepts" => [domain_id]})

      ElasticsearchMock
      |> expect(:request, fn
        _, :post, "/concepts/_search", %{aggs: _, size: 0, query: query}, [] ->
          assert %{bool: %{filter: [_status_filter, _confidential_filter]}} = query
          aggs_response()
      end)

      assert %{"data" => data} =
               conn
               |> get(Routes.business_concept_filter_path(conn, :index))
               |> json_response(:ok)

      assert data == %{"foo" => ["bar", "baz"]}
    end
  end

  defp aggs_response do
    {:ok, %{"aggregations" => %{"foo" => %{"buckets" => [%{"key" => "bar"}, %{"key" => "baz"}]}}}}
  end
end
