defmodule TdBg.BusinessConcepts.WorkflowTest do
  use TdBg.DataCase

  alias TdBg.Auth.Session
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.Workflow
  alias TdBg.Cache.ConceptLoader
  alias TdBg.Search.IndexWorker
  alias TdCache.Redix
  alias TdCache.Redix.Stream

  @stream TdCache.Audit.stream()

  setup_all do
    Redix.del!(@stream)
    start_supervised(ConceptLoader)
    start_supervised(IndexWorker)
    :ok
  end

  setup do
    on_exit(fn -> Redix.del!(@stream) end)
    [session: build(:session)]
  end

  describe "new_version/2" do
    test "creates a new published version and the previous version remains the current" do
      business_concept_version =
        insert(:business_concept_version, status: "published", current: true)

      assert {:ok, res} = Workflow.new_version(business_concept_version, %Session{user_id: 1234})
      assert %{current: %{current: false}} = res
      assert BusinessConcepts.get_business_concept_version!(business_concept_version.id).current
    end

    test "creates a new published version and advance to a publish state will make it current" do
      business_concept_version =
        insert(:business_concept_version, status: "published", current: true)

      assert {:ok, res} = Workflow.new_version(business_concept_version, %Session{user_id: 1234})
      assert %{current: %{current: false}} = res
      assert BusinessConcepts.get_business_concept_version!(business_concept_version.id).current

      assert {:ok, res} =
               Workflow.submit_business_concept_version(res.current, %Session{user_id: 1234})

      assert BusinessConcepts.get_business_concept_version!(business_concept_version.id).current

      assert {:ok, res} = Workflow.publish(res.updated, %Session{user_id: 1234})
      refute BusinessConcepts.get_business_concept_version!(business_concept_version.id).current
      assert BusinessConcepts.get_business_concept_version!(res.published.id).current
    end

    test "publishes an event to the audit stream" do
      business_concept_version = insert(:business_concept_version, status: "published")

      assert {:ok, %{audit: event_id}} =
               Workflow.new_version(business_concept_version, %Session{user_id: 1234})

      assert {:ok, [%{id: ^event_id}]} = Stream.read(:redix, @stream, transform: true)
    end
  end

  describe "publish_business_concept/2" do
    test "changes the status and audit fields" do
      %{last_change_at: ts} =
        business_concept_version = insert(:business_concept_version, status: "draft")

      %{user_id: user_id} = session = build(:session, user_id: 987)

      assert {:ok, %{published: published}} = Workflow.publish(business_concept_version, session)

      assert %{status: "published", last_change_by: ^user_id, last_change_at: last_change_at} =
               published

      assert DateTime.diff(last_change_at, ts, :microsecond) > 0
    end

    test "publishes an event including domain_ids to the audit stream", %{session: session} do
      business_concept_version = insert(:business_concept_version, status: "draft")

      assert {:ok, %{audit: event_id}} = Workflow.publish(business_concept_version, session)
      assert {:ok, [event]} = Stream.read(:redix, @stream, transform: true)
      assert %{id: ^event_id, payload: payload} = event
      assert %{"domain_ids" => _domain_ids} = Jason.decode!(payload)
    end
  end

  describe "reject/3" do
    test "rejects business_concept", %{session: session} do
      reason = "Because I want to"
      business_concept_version = insert(:business_concept_version, status: "pending_approval")

      assert {:ok, %{rejected: business_concept_version}} =
               Workflow.reject(business_concept_version, reason, session)

      assert %{status: "rejected", reject_reason: ^reason} = business_concept_version
    end

    test "publishes an event including domain_ids to the audit stream", %{session: session} do
      reason = "Because I want to"
      business_concept_version = insert(:business_concept_version, status: "pending_approval")

      assert {:ok, %{audit: event_id}} =
               Workflow.reject(business_concept_version, reason, session)

      assert {:ok, [event]} = Stream.read(:redix, @stream, transform: true)
      assert %{id: ^event_id, payload: payload} = event
      assert %{"domain_ids" => _domain_ids} = Jason.decode!(payload)
    end
  end

  describe "submit_business_concept_version/2" do
    test "updates the business_concept", %{session: session} do
      %{user_id: user_id} = session
      business_concept_version = insert(:business_concept_version)

      assert {:ok, %{updated: business_concept_version}} =
               Workflow.submit_business_concept_version(business_concept_version, session)

      assert %{status: "pending_approval", last_change_by: ^user_id} = business_concept_version
    end

    test "publishes an event including domain_ids to the audit stream", %{session: session} do
      business_concept_version = insert(:business_concept_version)

      assert {:ok, %{audit: event_id}} =
               Workflow.submit_business_concept_version(business_concept_version, session)

      assert {:ok, [event]} = Stream.read(:redix, @stream, transform: true)
      assert %{id: ^event_id, payload: payload} = event
      assert %{"domain_ids" => _domain_ids} = Jason.decode!(payload)
    end
  end
end
