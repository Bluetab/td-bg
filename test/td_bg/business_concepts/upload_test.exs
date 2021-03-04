defmodule TdBg.UploadTest do
  use TdBg.DataCase

  alias TdBg.BusinessConcept.Upload
  alias TdBg.BusinessConcepts
  alias TdBg.Cache.ConceptLoader
  alias TdBg.Search.IndexWorker

  setup_all do
    start_supervised(ConceptLoader)
    start_supervised(IndexWorker)
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
              },
              %{
                "cardinality" => "+",
                "description" => "description",
                "label" => "Role",
                "name" => "role",
                "type" => "user"
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
    test "from_csv/3 uploads business concept versions with valid data" do
      claims = build(:claims)
      insert(:domain, external_id: "domain")
      business_concept_upload = %{path: "test/fixtures/upload.csv"}

      assert {:ok, [concept_id | _]} =
               Upload.from_csv(business_concept_upload, claims, fn _, _ -> true end)

      version = BusinessConcepts.get_last_version_by_business_concept_id!(concept_id)
      concept = Map.get(version, :business_concept)
      assert Map.get(concept, :confidential)
      assert version |> Map.get(:content) |> Map.get("role") == ["Role"]
    end

    test "from_csv/3 returns error on invalid content" do
      claims = build(:claims)
      insert(:domain, external_id: "domain")
      business_concept_upload = %{path: "test/fixtures/incorrect_upload.csv"}

      assert {:error, changeset} =
               Upload.from_csv(business_concept_upload, claims, fn _, _ -> true end)

      message =
        changeset
        |> Map.get(:errors)
        |> Keyword.get(:critical)
        |> elem(0)

      assert message == "is invalid"
    end

    test "from_csv/3 Does not upload business concept versions without permissions" do
      claims = build(:claims)
      insert(:domain, external_id: "domain")
      business_concept_upload = %{path: "test/fixtures/upload.csv"}

      assert {:error, %{domain: %{external_id: "domain"}}} =
               Upload.from_csv(business_concept_upload, claims, fn _, _ -> false end)
    end
  end
end
