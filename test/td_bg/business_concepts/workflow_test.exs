defmodule TdBg.BusinessConcepts.WorkflowTest do
  use TdBg.DataCase

  alias TdBg.Accounts.User
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
    :ok
  end

  describe "new_version/2" do
    test "creates a new version and sets current to false on previous version" do
      business_concept_version = insert(:business_concept_version, status: "published")

      assert {:ok, res} =
               Workflow.new_version(
                 business_concept_version,
                 %User{id: 1234}
               )

      assert %{current: %{current: true}, previous: %{current: false}} = res
    end

    test "publishes an event to the audit stream" do
      business_concept_version = insert(:business_concept_version, status: "published")

      assert {:ok, %{audit: event_id} = res} =
               Workflow.new_version(business_concept_version, %User{id: 1234})

      assert {:ok, [%{id: ^event_id}]} = Stream.read(:redix, @stream, transform: true)
    end
  end

  describe "publish_business_concept/2" do
    test "changes the status and audit fields" do
      %{last_change_at: ts} =
        business_concept_version = insert(:business_concept_version, status: "draft")

      %{id: user_id} = user = build(:user, id: 987)

      assert {:ok, res} = Workflow.publish(business_concept_version, user)

      assert %{
               published: %{
                 status: "published",
                 last_change_by: ^user_id,
                 last_change_at: last_change_at
               }
             } = res

      assert DateTime.diff(last_change_at, ts, :microsecond) > 0
    end

    test "publishes an event to the audit stream" do
      business_concept_version = insert(:business_concept_version, status: "draft")
      user = build(:user)

      assert {:ok, %{audit: event_id} = res} = Workflow.publish(business_concept_version, user)

      assert {:ok, [%{id: ^event_id}]} = Stream.read(:redix, @stream, transform: true)
    end
  end

  describe "reject/3" do
    test "rejects business_concept" do
      reason = "Because I want to"
      business_concept_version = insert(:business_concept_version, status: "pending_approval")
      user = build(:user)

      assert {:ok, %{rejected: business_concept_version}} =
               Workflow.reject(business_concept_version, reason, user)

      assert %{status: "rejected", reject_reason: ^reason} = business_concept_version
    end

    test "publishes an event to the audit stream" do
      reason = "Because I want to"
      business_concept_version = insert(:business_concept_version, status: "pending_approval")
      user = build(:user)

      assert {:ok, %{audit: event_id} = res} =
               Workflow.reject(business_concept_version, reason, user)

      assert {:ok, [%{id: ^event_id}]} = Stream.read(:redix, @stream, transform: true)
    end
  end

  describe "submit_business_concept_version/2" do
    test "updates the business_concept" do
      %{id: user_id} = user = build(:user)
      business_concept_version = insert(:business_concept_version)

      assert {:ok, %{updated: business_concept_version}} =
               Workflow.submit_business_concept_version(business_concept_version, user)

      assert %{status: "pending_approval", last_change_by: ^user_id} = business_concept_version
    end
  end
end
