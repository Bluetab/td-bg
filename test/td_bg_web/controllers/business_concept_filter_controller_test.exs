defmodule TdBgWeb.BusinessConceptFilterControllerTest do
  use TdBgWeb.ConnCase

  import Mox

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
        _, :post, "/concepts/_search", %{aggs: _, size: 0, query: query}, [_] ->
          assert %{bool: %{must: %{match_all: %{}}}} = query
          aggs_response()
      end)

      assert %{"data" => data} =
               conn
               |> get(Routes.business_concept_filter_path(conn, :index))
               |> json_response(:ok)

      assert %{"foo" => %{"values" => ["bar", "baz"]}} = data
    end

    @tag authentication: [user_name: "not_an_admin"]
    test "lists all filters (non-admin user)", %{claims: claims, conn: conn} do
      %{id: domain_id} = CacheHelpers.insert_domain()
      put_session_permissions(claims, %{"view_published_business_concepts" => [domain_id]})

      ElasticsearchMock
      |> expect(:request, fn
        _, :post, "/concepts/_search", %{aggs: _, size: 0, query: query}, [_] ->
          assert %{bool: %{must: [_status_filter, _confidential_filter]}} = query
          aggs_response()
      end)

      assert %{"data" => data} =
               conn
               |> get(Routes.business_concept_filter_path(conn, :index))
               |> json_response(:ok)

      assert %{"foo" => %{"values" => ["bar", "baz"]}} = data
    end
  end

  defp aggs_response do
    {:ok, %{"aggregations" => %{"foo" => %{"buckets" => [%{"key" => "bar"}, %{"key" => "baz"}]}}}}
  end
end
