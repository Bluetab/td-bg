defmodule TdBgWeb.SearchControllerTest do
  use TdBgWeb.ConnCase

  alias TdCluster.TestHelpers.TdAiMock
  alias TdCore.Search.IndexWorkerMock

  @index_type "suggestions"

  describe "/api/business_concepts/search/embeddings/_put" do
    setup do
      IndexWorkerMock.clear()
      on_exit(fn -> IndexWorkerMock.clear() end)
      :ok
    end

    @tag authentication: [role: "admin"]
    test "triggers a put embeddings action", %{conn: conn} do
      TdAiMock.Indices.exists_enabled?(&Mox.expect/4, [index_type: @index_type], {:ok, true})

      assert conn
             |> post(Routes.search_path(conn, :embeddings, %{}))
             |> response(:accepted)

      assert [{:put_embeddings, :concepts, :all}] == IndexWorkerMock.calls()
    end

    @tag authentication: [role: "admin"]
    test "returns forbiddend when there are no indices enabled", %{conn: conn} do
      TdAiMock.Indices.exists_enabled?(&Mox.expect/4, [index_type: @index_type], {:ok, false})

      assert conn
             |> post(Routes.search_path(conn, :embeddings, %{}))
             |> response(:forbidden)

      assert [] == IndexWorkerMock.calls()
    end
  end
end
