defmodule TdBg.BusinessConcepts.AuditTest do
  use TdBg.DataCase

  import Mox

  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.Audit
  alias TdCache.Redix
  alias TdCache.Redix.Stream

  @stream TdCache.Audit.stream()

  setup_all do
    Redix.del!(@stream)
    start_supervised!(TdBg.Cache.ConceptLoader)
    :ok
  end

  setup do
    stub(MockClusterHandler, :call, fn :ai, TdAi.Indices, :exists_enabled?, [] ->
      {:ok, true}
    end)

    on_exit(fn -> Redix.del!(@stream) end)
    :ok
  end

  setup :set_mox_from_context

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

  describe "business_concept_version_updated" do
    test "publish event update_concept_draft when a draft is updated" do
      old_domain = CacheHelpers.insert_domain()
      %{id: new_domain_id} = CacheHelpers.insert_domain()

      concept = build(:business_concept, domain: old_domain)

      %{business_concept: business_concept} =
        business_concept_version =
        insert(:business_concept_version,
          business_concept: concept,
          status: "draft",
          content: %{}
        )

      changeset =
        Ecto.Changeset.change(business_concept, %{domain_id: new_domain_id})

      {:ok, _} =
        Audit.business_concept_version_updated(
          TdBg.Repo,
          %{updated: business_concept_version},
          changeset
        )

      assert {:ok, [%{event: event}]} = Stream.read(:redix, @stream, transform: true)

      assert event == "update_concept_draft"
    end

    test "publish event update_concept_draft when a a published concept is updated" do
      old_domain = CacheHelpers.insert_domain()
      %{id: new_domain_id} = CacheHelpers.insert_domain()

      concept = build(:business_concept, domain: old_domain)

      %{business_concept: business_concept} =
        business_concept_version =
        insert(:business_concept_version,
          business_concept: concept,
          status: "published",
          content: %{}
        )

      changeset =
        Ecto.Changeset.change(business_concept, %{domain_id: new_domain_id})

      {:ok, _} =
        Audit.business_concept_version_updated(
          TdBg.Repo,
          %{updated: business_concept_version},
          changeset
        )

      assert {:ok, [%{event: event}]} = Stream.read(:redix, @stream, transform: true)

      assert event == "update_concept"
    end
  end

  describe "business_concept_published" do
    test "publish event concept_published when called without changeset (via web)" do
      %{id: domain_id} = CacheHelpers.insert_domain()

      concept = build(:business_concept, domain_id: domain_id)

      business_concept_version =
        insert(:business_concept_version,
          business_concept: concept,
          status: "published",
          content: %{}
        )

      {:ok, _} =
        Audit.business_concept_published(
          TdBg.Repo,
          %{published: business_concept_version}
        )

      assert {:ok, events} = Stream.read(:redix, @stream, transform: true)

      assert length(events) == 1
      assert [%{event: "concept_published"}] = events
    end

    test "publish multiple events when called with changeset (via file)" do
      %{id: domain_id} = CacheHelpers.insert_domain()

      concept = build(:business_concept, domain_id: domain_id)

      business_concept_version =
        insert(:business_concept_version,
          business_concept: concept,
          status: "published",
          content: %{"Field1" => %{"value" => "value1", "origin" => "user"}}
        )

      Process.put(:event_via, "file")

      changeset =
        Ecto.Changeset.change(business_concept_version, %{
          content: %{"Field1" => %{"value" => "new_value", "origin" => "user"}}
        })

      {:ok, _} =
        Audit.business_concept_published(
          TdBg.Repo,
          %{published: business_concept_version},
          changeset
        )

      assert {:ok, events} = Stream.read(:redix, @stream, transform: true)

      assert length(events) >= 2

      event_types = Enum.map(events, & &1.event)

      assert "concept_published" in event_types
      assert "new_concept_draft" in event_types or "update_concept" in event_types
    end

    test "all events have event_via='file' when published via file with changeset" do
      %{id: domain_id} = CacheHelpers.insert_domain()

      concept = build(:business_concept, domain_id: domain_id)

      business_concept_version =
        insert(:business_concept_version,
          business_concept: concept,
          status: "published",
          content: %{"Field1" => %{"value" => "value1", "origin" => "user"}}
        )

      Process.put(:event_via, "file")

      changeset =
        Ecto.Changeset.change(business_concept_version, %{
          content: %{"Field1" => %{"value" => "new_value", "origin" => "user"}}
        })

      {:ok, _} =
        Audit.business_concept_published(
          TdBg.Repo,
          %{published: business_concept_version},
          changeset
        )

      assert {:ok, events} = Stream.read(:redix, @stream, transform: true)

      assert length(events) == 3

      assert Enum.all?(events, fn %{payload: payload} ->
               decoded = Jason.decode!(payload)
               Map.get(decoded, "event_via") == "file"
             end)
    end

    test "publish event with correct diff when fields are updated, removed, added or origin changed" do
      %{id: domain_id} = CacheHelpers.insert_domain()

      concept = build(:business_concept, domain_id: domain_id)

      initial_content = %{
        "FieldA" => %{"value" => "foo", "origin" => "user"},
        "FieldB" => %{"value" => "bar", "origin" => "user"},
        "FieldC" => %{"value" => "baz", "origin" => "user"},
        "FieldD" => %{"value" => "zar", "origin" => "user"}
      }

      business_concept_version =
        insert(:business_concept_version,
          business_concept: concept,
          status: "published",
          content: initial_content
        )

      new_content = %{
        "FieldA" => %{"value" => "fuu", "origin" => "file"},
        "FieldB" => %{"value" => "bar", "origin" => "file"},
        "FieldD" => %{"value" => "", "origin" => "file"},
        "FieldE" => %{"value" => "faz", "origin" => "file"}
      }

      Process.put(:event_via, "file")

      changeset =
        Ecto.Changeset.change(business_concept_version, %{
          content: new_content
        })

      {:ok, _} =
        Audit.business_concept_published(
          TdBg.Repo,
          %{published: business_concept_version},
          changeset
        )

      assert {:ok, events} = Stream.read(:redix, @stream, transform: true)

      event = Enum.find(events, &(&1.event == "update_concept_draft"))
      assert event

      payload = Jason.decode!(event.payload)
      content_diff = payload["content"]

      assert content_diff["changed"] == %{"FieldA" => "fuu", "FieldD" => ""}
      assert content_diff["added"] == %{"FieldE" => "faz"}
    end
  end
end
