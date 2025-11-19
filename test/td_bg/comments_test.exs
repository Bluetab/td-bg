defmodule TdBg.CommentsTest do
  use TdBg.DataCase

  alias TdBg.Comments
  alias TdBg.Comments.Comment
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
      bcv = insert(:business_concept_version, domain_id: domain_id)

    CacheHelpers.put_concept(concept, bcv)

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

    test "creates a comment for ingest resource type", %{claims: claims} do
      TdCache.IngestCache.put(%{id: 1, name: "Test Ingest"})
      params = string_params_for(:comment, resource_id: 1, resource_type: "ingest")

      assert {:ok, %{resource: _, comment: _, audit: _event_id}} =
               Comments.create_comment(params, claims)
    end

    test "returns error when creating comment with invalid params", %{claims: claims} do
      params = %{resource_id: "invalid"}

      assert {:error, :comment, changeset, _} = Comments.create_comment(params, claims)
      refute changeset.valid?
    end
  end

  describe "delete_comment/2" do
    test "deletes a comment and publishes an event to the audit stream", %{claims: claims} do
      comment = insert(:comment)

      assert {:ok, %{comment: _, audit: event_id}} = Comments.delete_comment(comment, claims)
      assert {:ok, [%{id: ^event_id}]} = Stream.read(:redix, @stream, transform: true)
    end
  end

  describe "list_comments/0" do
    test "returns all comments ordered by inserted_at desc" do
      comment1 = insert(:comment, content: "First comment")
      comment2 = insert(:comment, content: "Second comment")

      comments = Comments.list_comments()

      assert length(comments) >= 2
      assert comment1.id in Enum.map(comments, & &1.id)
      assert comment2.id in Enum.map(comments, & &1.id)
    end
  end

  describe "list_comments_by_filters/1" do
    test "returns filtered comments by resource_type" do
      insert(:comment, resource_type: "business_concept")
      insert(:comment, resource_type: "ingest")

      filtered = Comments.list_comments_by_filters(%{"resource_type" => "business_concept"})

      assert Enum.all?(filtered, &(&1.resource_type == "business_concept"))
    end

    test "returns filtered comments by resource_id" do
      comment = insert(:comment, resource_id: 999)

      filtered = Comments.list_comments_by_filters(%{"resource_id" => 999})

      assert [comment_id] = Enum.map(filtered, & &1.id)
      assert comment_id == comment.id
    end

    test "returns empty list when no comments match filters" do
      filtered = Comments.list_comments_by_filters(%{"resource_type" => "nonexistent"})

      assert filtered == []
    end
  end

  describe "filter/2" do
    test "builds dynamic where clause with valid fields" do
      params = %{"resource_type" => "business_concept", "resource_id" => 1}
      fields = Comment.__schema__(:fields)

      dynamic = Comments.filter(params, fields)

      assert dynamic
    end

    test "ignores invalid fields" do
      params = %{"resource_type" => "business_concept", "invalid_field" => "value"}
      fields = Comment.__schema__(:fields)

      dynamic = Comments.filter(params, fields)

      assert dynamic
    end
  end

  describe "get_comment/1" do
    test "returns comment when it exists" do
      comment = insert(:comment)

      assert {:ok, found_comment} = Comments.get_comment(comment.id)
      assert found_comment.id == comment.id
    end

    test "returns error when comment does not exist" do
      assert {:error, :not_found} = Comments.get_comment(-1)
    end
  end

  describe "get_comment_by_resource/2" do
    test "returns comment when it exists" do
      comment = insert(:comment, resource_type: "business_concept", resource_id: 123)

      found = Comments.get_comment_by_resource("business_concept", 123)

      assert found.id == comment.id
    end

    test "returns nil when comment does not exist" do
      assert nil == Comments.get_comment_by_resource("business_concept", -1)
    end
  end
end
