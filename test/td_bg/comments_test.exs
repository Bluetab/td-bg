defmodule TdBg.CommentsTest do
  use TdBg.DataCase

  alias TdBg.Comments
  alias TdCache.Redix
  alias TdCache.Redix.Stream

  @stream TdCache.Audit.stream()

  setup_all do
    Redix.del!(@stream)
    :ok
  end

  setup do
    on_exit(fn -> Redix.del!(@stream) end)

    %{id: domain_id} = CacheHelpers.insert_domain()

    %{business_concept_id: concept_id, business_concept: concept} =
      insert(:business_concept_version, domain_id: domain_id)

    CacheHelpers.put_concept(concept)

    [claims: build(:claims, role: "admin"), resource_id: concept_id]
  end

  describe "create_comment/2" do
    test "creates a comment and publishes an event including domain_ids to the audit stream", %{
      claims: claims,
      resource_id: resource_id
    } do
      params = string_params_for(:comment, resource_id: resource_id)

      assert {:ok, %{resource: _, comment: _, audit: event_id}} =
               Comments.create_comment(params, claims)

      assert {:ok, [%{id: ^event_id, payload: payload}]} =
               Stream.read(:redix, @stream, transform: true)

      assert %{"domain_ids" => _domain_ids} = Jason.decode!(payload)
    end
  end

  describe "delete_comment/2" do
    test "deletes a comment and publishes an event to the audit stream", %{claims: claims} do
      comment = insert(:comment)

      assert {:ok, %{comment: _, audit: event_id}} = Comments.delete_comment(comment, claims)
      assert {:ok, [%{id: ^event_id}]} = Stream.read(:redix, @stream, transform: true)
    end
  end
end
