defmodule TdBg.BusinessConcepts.WorkflowTest do
  use TdBg.DataCase

  alias TdBg.Auth.Claims
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.Workflow
  alias TdBg.Cache.ConceptLoader
  alias TdBg.Search.IndexWorker
  alias TdCache.Redix
  alias TdCache.Redix.Stream
  alias TdCache.TaxonomyCache

  @stream TdCache.Audit.stream()

  setup_all do
    Redix.del!(@stream)
    start_supervised(ConceptLoader)
    start_supervised(IndexWorker)
    :ok
  end

  setup do
    on_exit(fn -> Redix.del!(@stream) end)
    [claims: build(:claims)]
  end

  describe "new_version/2" do
    test "creates a new published version and the previous version remains the current" do
      business_concept_version =
        insert(:business_concept_version, status: "published", current: true)

      assert {:ok, res} = Workflow.new_version(business_concept_version, %Claims{user_id: 1234})
      assert %{current: %{current: false}} = res
      assert BusinessConcepts.get_business_concept_version!(business_concept_version.id).current
    end

    test "creates a new published version and advance to a publish state will make it current" do
      business_concept_version =
        insert(:business_concept_version, status: "published", current: true)

      assert {:ok, res} = Workflow.new_version(business_concept_version, %Claims{user_id: 1234})
      assert %{current: %{current: false}} = res
      assert BusinessConcepts.get_business_concept_version!(business_concept_version.id).current

      assert {:ok, res} =
               Workflow.submit_business_concept_version(res.current, %Claims{user_id: 1234})

      assert BusinessConcepts.get_business_concept_version!(business_concept_version.id).current

      assert {:ok, res} = Workflow.publish(res.updated, %Claims{user_id: 1234})
      refute BusinessConcepts.get_business_concept_version!(business_concept_version.id).current
      assert BusinessConcepts.get_business_concept_version!(res.published.id).current
    end

    test "publishes an event to the audit stream" do
      business_concept_version = insert(:business_concept_version, status: "published")

      assert {:ok, %{audit: event_id}} =
               Workflow.new_version(business_concept_version, %Claims{user_id: 1234})

      assert {:ok, [%{id: ^event_id}]} = Stream.read(:redix, @stream, transform: true)
    end

    setup [:create_concept_with_parents]

    test "publishes an event to the audit stream with domain ids", %{
      concept: concept,
      domain_ids: domain_ids
    } do
      business_concept_version =
        insert(:business_concept_version, status: "published", business_concept: concept)

      assert {:ok, %{audit: event_id}} =
               Workflow.new_version(business_concept_version, %Claims{user_id: 1234})

      assert {:ok, [%{id: ^event_id, payload: payload}]} =
               Stream.read(:redix, @stream, transform: true)

      assert %{"domain_ids" => ^domain_ids} = Jason.decode!(payload)
    end
  end

  describe "publish_business_concept/2" do
    test "changes the status and audit fields" do
      %{last_change_at: ts} =
        business_concept_version = insert(:business_concept_version, status: "draft")

      %{user_id: user_id} = claims = build(:claims, user_id: 987)

      assert {:ok, %{published: published}} = Workflow.publish(business_concept_version, claims)

      assert %{status: "published", last_change_by: ^user_id, last_change_at: last_change_at} =
               published

      assert DateTime.diff(last_change_at, ts, :microsecond) > 0
    end

    setup [:create_concept_with_parents]

    test "publishes an event including domain_ids to the audit stream", %{
      claims: claims,
      concept: concept,
      domain_ids: domain_ids
    } do
      business_concept_version =
        insert(:business_concept_version, status: "draft", business_concept: concept)

      assert {:ok, %{audit: event_id}} = Workflow.publish(business_concept_version, claims)
      assert {:ok, [event]} = Stream.read(:redix, @stream, transform: true)
      assert %{id: ^event_id, payload: payload} = event
      assert %{"domain_ids" => ^domain_ids} = Jason.decode!(payload)
    end

    test "publishes an event including subscribable_fields", %{claims: claims} do
      business_concept_version = insert(:business_concept_version, status: "draft")

      assert {:ok, %{audit: event_id}} = Workflow.publish(business_concept_version, claims)
      assert {:ok, [event]} = Stream.read(:redix, @stream, transform: true)
      assert %{id: ^event_id, payload: payload} = event
      assert %{"subscribable_fields" => _} = Jason.decode!(payload)
    end
  end

  describe "reject/3" do
    test "rejects business_concept", %{claims: claims} do
      reason = "Because I want to"
      business_concept_version = insert(:business_concept_version, status: "pending_approval")

      assert {:ok, %{rejected: business_concept_version}} =
               Workflow.reject(business_concept_version, reason, claims)

      assert %{status: "rejected", reject_reason: ^reason} = business_concept_version
    end

    setup [:create_concept_with_parents]

    test "publishes an event including domain_ids to the audit stream", %{
      claims: claims,
      concept: concept,
      domain_ids: domain_ids
    } do
      reason = "Because I want to"

      business_concept_version =
        insert(:business_concept_version, status: "pending_approval", business_concept: concept)

      assert {:ok, %{audit: event_id}} = Workflow.reject(business_concept_version, reason, claims)

      assert {:ok, [event]} = Stream.read(:redix, @stream, transform: true)
      assert %{id: ^event_id, payload: payload} = event
      assert %{"domain_ids" => ^domain_ids} = Jason.decode!(payload)
    end
  end

  describe "submit_business_concept_version/2" do
    test "updates the business_concept", %{claims: claims} do
      %{user_id: user_id} = claims
      business_concept_version = insert(:business_concept_version)

      assert {:ok, %{updated: business_concept_version}} =
               Workflow.submit_business_concept_version(business_concept_version, claims)

      assert %{status: "pending_approval", last_change_by: ^user_id} = business_concept_version
    end

    setup [:create_concept_with_parents]

    test "publishes an event including domain_ids to the audit stream", %{
      claims: claims,
      concept: concept,
      domain_ids: domain_ids
    } do
      business_concept_version = insert(:business_concept_version, business_concept: concept)

      assert {:ok, %{audit: event_id}} =
               Workflow.submit_business_concept_version(business_concept_version, claims)

      assert {:ok, [event]} = Stream.read(:redix, @stream, transform: true)
      assert %{id: ^event_id, payload: payload} = event
      assert %{"domain_ids" => ^domain_ids} = Jason.decode!(payload)
    end
  end

  defp create_concept_with_parents(_) do
    domain_id = System.unique_integer([:positive])
    on_exit(fn -> TaxonomyCache.delete_domain(domain_id) end)
    parent_ids = Enum.map(1..5, fn _ -> System.unique_integer([:positive]) end)
    domain_ids = [domain_id | parent_ids]

    domain = %{
      id: domain_id,
      name: "foo",
      external_id: "foo",
      updated_at: DateTime.utc_now(),
      parent_ids: parent_ids
    }

    TaxonomyCache.put_domain(domain)
    domain = build(:domain, id: domain_id)
    concept = build(:business_concept, domain: domain)
    [concept: concept, domain_ids: domain_ids]
  end
end
