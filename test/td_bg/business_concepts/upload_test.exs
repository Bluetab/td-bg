defmodule TdBg.UploadTest do
  use TdBg.DataCase

  alias TdBg.BusinessConcept.Upload
  alias TdBg.Cache.ConceptLoader
  alias TdBg.Search.IndexWorker
  alias TdBgWeb.ApiServices.MockTdAuditService
  alias TdBgWeb.ApiServices.MockTdAuthService

  setup_all do
    start_supervised(ConceptLoader)
    start_supervised(IndexWorker)
    start_supervised(MockTdAuthService)
    start_supervised(MockTdAuditService)
    :ok
  end

  setup _context do
    %{id: template_id} =
      Templates.create_template(%{
        name: "term",
        content: [
          %{
            "name" => "group",
            "fields" => [
              %{
                "cardinality" => "1",
                "default" => "",
                "description" => "description",
                "label" => "critical term",
                "name" => "critical",
                "type" => "string",
                "values" => %{
                  "fixed" => ["Yes", "No"]
                }
              }
            ]
          }
        ],
        scope: "test",
        label: "term",
        id: "999"
      })

    on_exit(fn ->
      Templates.delete(template_id)
    end)

    :ok
  end

  describe "business_concept_upload" do
    test "from_csv/2 uploads business concept versions with valid data" do
      user = build(:user)
      insert(:domain, name: "domain")
      business_concept_upload = %{path: "test/fixtures/upload.csv"}
      assert {:ok, [_ | _]} = Upload.from_csv(business_concept_upload, user)
    end

    test "from_csv/2 returns error on invalid content" do
      user = build(:user)
      insert(:domain, name: "domain")
      business_concept_upload = %{path: "test/fixtures/incorrect_upload.csv"}
      assert {:error, changeset} = Upload.from_csv(business_concept_upload, user)

      message =
        changeset
        |> Map.get(:errors)
        |> Keyword.get(:critical)
        |> elem(0)

      assert message == "is invalid"
    end
  end
end
