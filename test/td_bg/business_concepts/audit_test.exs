defmodule TdBg.BusinessConcepts.AuditTest do
  use TdBg.DataCase

  alias TdBg.BusinessConcepts
  alias TdCache.Redix
  alias TdCache.Redix.Stream

  @stream TdCache.Audit.stream()

  setup_all do
    Redix.del!(@stream)
    start_supervised!(TdBg.Cache.ConceptLoader)
    :ok
  end

  setup do
    on_exit(fn -> Redix.del!(@stream) end)
    :ok
  end

  describe "business_concepts_updated" do
    test "publish and event for domain updated" do
      %{user_id: user_id} = build(:claims, role: "admin")

      %{id: domain_old_id} = domain = CacheHelpers.insert_domain()
      %{id: domain_new_id} = CacheHelpers.insert_domain()

      concept = build(:business_concept, domain: domain)

      business_concept_version =
        insert(:business_concept_version,
          business_concept: concept,
          content: %{}
        )

      update_attrs =
        %{
          "business_concept" => %{
            "domain_id" => domain_new_id,
            "last_change_by" => user_id,
            "last_change_at" => DateTime.utc_now()
          }
        }

      assert {:ok, _} =
               BusinessConcepts.update_business_concept(
                 business_concept_version,
                 update_attrs
               )

      assert {:ok, [%{payload: payload}]} = Stream.read(:redix, @stream, transform: true)

      assert %{
               "domain_id" => ^domain_new_id,
               "domain_ids" => [^domain_new_id],
               "domain_new" => %{
                 "id" => ^domain_new_id
               },
               "domain_old" => %{
                 "id" => ^domain_old_id
               }
             } = Jason.decode!(payload)
    end
  end
end
