defmodule TdBg.CommentsTest do
  use TdBg.DataCase

  alias TdBg.Comments
  alias TdCache.ConceptCache
  alias TdCache.DomainCache
  alias TdCache.Redix
  alias TdCache.Redix.Stream

  @stream TdCache.Audit.stream()

  setup_all do
    Redix.del!(@stream)
    :ok
  end

  setup do
    %{id: domain_id} = domain = insert(:domain)
    %{id: business_concept_id} = concept = insert(:business_concept, domain: domain)
    insert(:business_concept_version, business_concept_id: business_concept_id)

    DomainCache.put(domain)
    ConceptCache.put(concept)

    on_exit(fn ->
      ConceptCache.delete(business_concept_id)
      DomainCache.delete(domain_id)
      Redix.del!(@stream)
    end)

    session = build(:session, role: "admin")
    [session: session, resource_id: business_concept_id]
  end

  describe "create_comment/2" do
    test "creates a comment and publishes an event including domain_ids to the audit stream", %{
      session: session,
      resource_id: resource_id
    } do
      params = string_params_for(:comment, resource_id: resource_id)

      assert {:ok, %{resource: _, comment: _, audit: event_id}} =
               Comments.create_comment(params, session)

      assert {:ok, [%{id: ^event_id, payload: payload}]} =
               Stream.read(:redix, @stream, transform: true)

      assert %{"domain_ids" => _domain_ids} = Jason.decode!(payload)
    end
  end

  describe "delete_comment/2" do
    test "deletes a comment and publishes an event to the audit stream", %{session: session} do
      comment = insert(:comment)

      assert {:ok, %{comment: _, audit: event_id}} = Comments.delete_comment(comment, session)
      assert {:ok, [%{id: ^event_id}]} = Stream.read(:redix, @stream, transform: true)
    end
  end
end
