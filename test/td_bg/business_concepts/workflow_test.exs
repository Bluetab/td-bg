defmodule TdBg.BusinessConcepts.WorkflowTest do
  use TdBg.DataCase

  import Mox

  alias TdBg.Auth.Claims
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.Workflow
  alias TdCache.Redix
  alias TdCache.Redix.Stream
  alias TdCore.Search.IndexWorkerMock

  @stream TdCache.Audit.stream()
  @template_name "test_template"

  setup_all do
    Redix.del!(@stream)
    start_supervised!(TdBg.Cache.ConceptLoader)
    :ok
  end

  setup do
    on_exit(fn ->
      Redix.del!(@stream)
      IndexWorkerMock.clear()
    end)

    [claims: build(:claims)]
  end

  setup :verify_on_exit!
  setup :set_mox_from_context

  setup do
    on_exit(fn -> Redix.del!(@stream) end)

    Templates.create_template(@template_name)

    [claims: build(:claims)]
  end

  describe "new_version/2" do
    setup :create_concept_with_parents

    setup do
      identifier_name = "identifier"

      with_identifier = %{
        id: System.unique_integer([:positive]),
        name: "Business concept template with identifier field",
        label: "concept_with_identifier",
        scope: "ie",
        content: [
          %{
            "fields" => [
              %{
                "cardinality" => "1",
                "default" => "",
                "label" => "Identifier",
                "name" => identifier_name,
                "subscribable" => false,
                "type" => "string",
                "values" => nil,
                "widget" => "identifier"
              }
            ],
            "name" => ""
          }
        ]
      }

      template_with_identifier = CacheHelpers.insert_template(with_identifier)
      [template_with_identifier: template_with_identifier, identifier_name: identifier_name]
    end

    test "creates a new published version and the previous version remains the current" do
      IndexWorkerMock.clear()

      business_concept_version =
        insert(:business_concept_version, status: "published", current: true, type: @template_name)

      assert {:ok, res} = Workflow.new_version(business_concept_version, %Claims{user_id: 1234})

      assert %{current: %{current: false, business_concept_id: id}} = res
      assert BusinessConcepts.get_business_concept_version!(business_concept_version.id).current
      assert IndexWorkerMock.calls() == [{:reindex, :concepts, [id]}]
      IndexWorkerMock.clear()
    end

    test "creates a new version and copies the identifier from the previous version one", %{
      claims: claims,
      template_with_identifier: template_with_identifier,
      identifier_name: identifier_name
    } do
      IndexWorkerMock.clear()
      existing_identifier = "00000000-0000-0000-0000-000000000000"
      concept = build(:business_concept, %{type: template_with_identifier.name})

      concept_version =
        insert(:business_concept_version, %{
          status: "published",
          business_concept: concept,
          content: %{"identifier" => existing_identifier}
        })

      assert {:ok, res} = Workflow.new_version(concept_version, claims)

      assert %{
               current: %{
                 content: %{^identifier_name => ^existing_identifier},
                 business_concept_id: id
               }
             } = res

      assert IndexWorkerMock.calls() == [{:reindex, :concepts, [id]}]
      IndexWorkerMock.clear()
    end

    test "creates a new published version and advance to a publish state will make it current" do
      IndexWorkerMock.clear()

      business_concept_version =
        insert(:business_concept_version, status: "published", current: true, type: @template_name)

      assert {:ok, res} = Workflow.new_version(business_concept_version, %Claims{user_id: 1234})
      assert %{current: %{current: false}} = res
      assert BusinessConcepts.get_business_concept_version!(business_concept_version.id).current

      assert {:ok, res} =
               Workflow.submit_business_concept_version(res.current, %Claims{user_id: 1234})

      assert BusinessConcepts.get_business_concept_version!(business_concept_version.id).current

      assert {:ok, res} = Workflow.publish(res.updated, %Claims{user_id: 1234})
      refute BusinessConcepts.get_business_concept_version!(business_concept_version.id).current
      assert BusinessConcepts.get_business_concept_version!(res.published.id).current

      assert [_, _, _] = IndexWorkerMock.calls()
      IndexWorkerMock.clear()
    end

    test "publishes an event to the audit stream" do
      IndexWorkerMock.clear()

      business_concept_version =
        insert(:business_concept_version, status: "published", type: @template_name)

      assert {:ok, %{audit: event_id}} =
               Workflow.new_version(business_concept_version, %Claims{user_id: 1234})

      assert {:ok, [%{id: ^event_id}]} = Stream.read(:redix, @stream, transform: true)
      assert [_] = IndexWorkerMock.calls()
      IndexWorkerMock.clear()
    end

    test "publishes an event to the audit stream with domain ids", %{
      concept: concept,
      domain_ids: domain_ids
    } do
      IndexWorkerMock.clear()

      business_concept_version =
        insert(:business_concept_version,
          status: "published",
          business_concept: concept
        )

      assert {:ok, %{audit: event_id}} =
               Workflow.new_version(business_concept_version, %Claims{user_id: 1234})

      assert {:ok, [%{id: ^event_id, payload: payload}]} =
               Stream.read(:redix, @stream, transform: true)

      assert %{"domain_ids" => ^domain_ids} = Jason.decode!(payload)
      assert [{:reindex, :concepts, [_]}] = IndexWorkerMock.calls()
      IndexWorkerMock.clear()
    end
  end

  describe "publish_business_concept/2" do
    setup :create_concept_with_parents

    test "changes the status and audit fields" do
      IndexWorkerMock.clear()

      %{last_change_at: ts} =
        business_concept_version = insert(:business_concept_version, status: "draft")

      %{user_id: user_id} = claims = build(:claims, user_id: 987)

      assert {:ok, %{published: published}} = Workflow.publish(business_concept_version, claims)

      assert %{status: "published", last_change_by: ^user_id, last_change_at: last_change_at} =
               published

      assert DateTime.diff(last_change_at, ts, :microsecond) > 0
      assert [{:reindex, :concepts, _}] = IndexWorkerMock.calls()
      IndexWorkerMock.clear()
    end

    test "publishes an event including domain_ids to the audit stream", %{
      claims: claims,
      concept: concept,
      domain_ids: domain_ids
    } do
      IndexWorkerMock.clear()

      business_concept_version =
        insert(:business_concept_version, status: "draft", business_concept: concept)

      assert {:ok, %{audit: event_id}} = Workflow.publish(business_concept_version, claims)
      assert {:ok, [event]} = Stream.read(:redix, @stream, transform: true)
      assert %{id: ^event_id, payload: payload} = event
      assert %{"domain_ids" => ^domain_ids} = Jason.decode!(payload)

      assert [{:reindex, :concepts, _}] = IndexWorkerMock.calls()
      IndexWorkerMock.clear()
    end

    test "publishes an event including subscribable_fields", %{claims: claims} do
      IndexWorkerMock.clear()
      business_concept_version = insert(:business_concept_version, status: "draft")

      assert {:ok, %{audit: event_id}} = Workflow.publish(business_concept_version, claims)
      assert {:ok, [event]} = Stream.read(:redix, @stream, transform: true)
      assert %{id: ^event_id, payload: payload} = event
      assert %{"subscribable_fields" => _} = Jason.decode!(payload)
      assert [{:reindex, :concepts, _}] = IndexWorkerMock.calls()
      IndexWorkerMock.clear()
    end
  end

  describe "reject/3" do
    setup :create_concept_with_parents

    test "rejects business_concept", %{claims: claims} do
      IndexWorkerMock.clear()
      reason = "Because I want to"
      business_concept_version = insert(:business_concept_version, status: "pending_approval")

      assert {:ok, %{rejected: business_concept_version}} =
               Workflow.reject(business_concept_version, reason, claims)

      assert %{status: "rejected", reject_reason: ^reason, business_concept_id: concept_id} =
               business_concept_version

      assert [{:reindex, :concepts, [concept_id]}] == IndexWorkerMock.calls()
      IndexWorkerMock.clear()
    end

    test "publishes an event including domain_ids to the audit stream", %{
      claims: claims,
      concept: concept,
      domain_ids: domain_ids
    } do
      IndexWorkerMock.clear()
      reason = "Because I want to"

      business_concept_version =
        insert(:business_concept_version, status: "pending_approval", business_concept: concept)

      assert {:ok, %{audit: event_id}} = Workflow.reject(business_concept_version, reason, claims)

      assert {:ok, [event]} = Stream.read(:redix, @stream, transform: true)
      assert %{id: ^event_id, payload: payload} = event
      assert %{"domain_ids" => ^domain_ids} = Jason.decode!(payload)
      assert [{:reindex, :concepts, [_]}] = IndexWorkerMock.calls()
      IndexWorkerMock.clear()
    end
  end

  describe "submit_business_concept_version/2" do
    setup :create_concept_with_parents

    test "updates the business_concept", %{claims: claims} do
      IndexWorkerMock.clear()
      %{user_id: user_id} = claims
      business_concept_version = insert(:business_concept_version)

      assert {:ok, %{updated: %{business_concept_id: id} = business_concept_version}} =
               Workflow.submit_business_concept_version(business_concept_version, claims)

      assert IndexWorkerMock.calls() == [{:reindex, :concepts, [id]}]

      assert %{status: "pending_approval", last_change_by: ^user_id} = business_concept_version
      IndexWorkerMock.clear()
    end

    test "publishes an event including domain_ids to the audit stream", %{
      claims: claims,
      concept: concept,
      domain_ids: domain_ids
    } do
      IndexWorkerMock.clear()
      business_concept_version = insert(:business_concept_version, business_concept: concept)

      assert {:ok, %{audit: event_id}} =
               Workflow.submit_business_concept_version(business_concept_version, claims)

      assert {:ok, [event]} = Stream.read(:redix, @stream, transform: true)
      assert %{id: ^event_id, payload: payload} = event
      assert %{"domain_ids" => ^domain_ids} = Jason.decode!(payload)
      assert [{:reindex, :concepts, _}] = IndexWorkerMock.calls()
      IndexWorkerMock.clear()
    end
  end

  defp create_concept_with_parents(_) do
    [domain | _] = domains = create_hierarchy(5, %{id: nil}) |> Enum.reverse()

    Enum.each(domains, &CacheHelpers.put_domain/1)
    domain_ids = Enum.map(domains, & &1.id)

    concept = build(:business_concept, domain: domain, type: @template_name)
    [concept: concept, domain_ids: domain_ids]
  end

  defp create_hierarchy(0, _), do: []

  defp create_hierarchy(depth, %{id: parent_id}) do
    domain = insert(:domain, parent_id: parent_id)
    [domain | create_hierarchy(depth - 1, domain)]
  end
end
