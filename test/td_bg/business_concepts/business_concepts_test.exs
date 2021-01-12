defmodule TdBg.BusinessConceptsTest do
  use TdBg.DataCase

  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Cache.ConceptLoader
  alias TdBg.Cache.DomainLoader
  alias TdBg.Repo
  alias TdBg.Search.IndexWorker
  alias TdCache.Redix
  alias TdDfLib.RichText

  @stream TdCache.Audit.stream()
  @template_name "TestTemplate1234"

  setup_all do
    Redix.del!(@stream)
    start_supervised(ConceptLoader)
    start_supervised(DomainLoader)
    start_supervised(IndexWorker)
    :ok
  end

  setup context do
    on_exit(fn -> Redix.del!(@stream) end)

    case context[:template] do
      nil ->
        :ok

      content ->
        Templates.create_template(%{
          id: 0,
          name: @template_name,
          label: "label",
          scope: "test",
          content: content
        })
    end

    :ok
  end

  describe "create_business_concept/1" do
    test "with valid data creates a business_concept" do
      %{user_id: user_id} = build(:session)
      domain = insert(:domain)

      concept_attrs = %{
        type: "some_type",
        domain_id: domain.id,
        last_change_by: user_id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        content: %{},
        name: "some name",
        description: to_rich_text("some description"),
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      creation_attrs = Map.put(version_attrs, :content_schema, [])

      assert {:ok, %{business_concept_version: business_concept_version}} =
               BusinessConcepts.create_business_concept(creation_attrs)

      assert business_concept_version.content == version_attrs.content
      assert business_concept_version.name == version_attrs.name
      assert business_concept_version.description == version_attrs.description
      assert business_concept_version.last_change_by == version_attrs.last_change_by
      assert business_concept_version.current == true
      assert business_concept_version.version == version_attrs.version
      assert business_concept_version.in_progress == false
      assert business_concept_version.business_concept.type == concept_attrs.type
      assert business_concept_version.business_concept.domain_id == concept_attrs.domain_id

      assert business_concept_version.business_concept.last_change_by ==
               concept_attrs.last_change_by
    end

    test "with invalid data returns error changeset" do
      version_attrs = %{
        business_concept: nil,
        content: %{},
        name: nil,
        description: nil,
        last_change_by: nil,
        last_change_at: nil,
        version: nil
      }

      creation_attrs = Map.put(version_attrs, :content_schema, [])

      assert {:error, :business_concept_version, %Ecto.Changeset{}, _} =
               BusinessConcepts.create_business_concept(creation_attrs)
    end

    test "with content" do
      %{user_id: user_id} = build(:session)
      domain = insert(:domain)

      content_schema = [
        %{"name" => "Field1", "type" => "string", "cardinality" => "?"},
        %{
          "name" => "Field2",
          "type" => "string",
          "cardinality" => "?",
          "values" => %{"fixed" => ["Hello", "World"]}
        },
        %{"name" => "Field3", "type" => "string", "cardinality" => "?"}
      ]

      content = %{"Field1" => "Hello", "Field2" => "World", "Field3" => ["Hellow", "World"]}

      concept_attrs = %{
        type: "some_type",
        domain_id: domain.id,
        last_change_by: user_id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        content: content,
        name: "some name",
        description: to_rich_text("some description"),
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)

      assert {:ok, %{business_concept_version: business_concept_version}} =
               BusinessConcepts.create_business_concept(creation_attrs)

      assert %{content: ^content} = business_concept_version
    end

    test "with invalid content: required" do
      %{user_id: user_id} = build(:session)
      domain = insert(:domain)

      content_schema = [
        %{"name" => "Field1", "type" => "string", "cardinality" => "1"},
        %{"name" => "Field2", "type" => "string", "cardinality" => "1"}
      ]

      content = %{}

      concept_attrs = %{
        type: "some_type",
        domain_id: domain.id,
        last_change_by: user_id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        content: content,
        name: "some name",
        description: to_rich_text("some description"),
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)

      assert {:ok, %{business_concept_version: business_concept_version}} =
               BusinessConcepts.create_business_concept(creation_attrs)

      assert business_concept_version.content == version_attrs.content
      assert business_concept_version.name == version_attrs.name
      assert business_concept_version.description == version_attrs.description
      assert business_concept_version.last_change_by == version_attrs.last_change_by
      assert business_concept_version.current == true
      assert business_concept_version.in_progress == true
      assert business_concept_version.version == version_attrs.version
      assert business_concept_version.business_concept.type == concept_attrs.type
      assert business_concept_version.business_concept.domain_id == concept_attrs.domain_id

      assert business_concept_version.business_concept.last_change_by ==
               concept_attrs.last_change_by
    end

    test "with content: default values" do
      %{user_id: user_id} = build(:session)
      domain = insert(:domain)

      content_schema = [
        %{"name" => "Field1", "type" => "string", "default" => "Hello", "cardinality" => "?"},
        %{"name" => "Field2", "type" => "string", "default" => "World", "cardinality" => "?"}
      ]

      content = %{}

      concept_attrs = %{
        type: "some_type",
        domain_id: domain.id,
        last_change_by: user_id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        content: content,
        name: "some name",
        description: to_rich_text("some description"),
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)

      assert {:ok, %{business_concept_version: business_concept_version}} =
               BusinessConcepts.create_business_concept(creation_attrs)

      assert %{content: content} = business_concept_version
      assert %{"Field1" => "Hello", "Field2" => "World"} = content
    end

    test "with invalid content: invalid variable list" do
      %{user_id: user_id} = build(:session)
      domain = insert(:domain)

      content_schema = [%{"name" => "Field1", "type" => "string", "cardinality" => "1"}]
      content = %{"Field1" => ["World", "World2"]}

      concept_attrs = %{
        type: "some_type",
        domain_id: domain.id,
        last_change_by: user_id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        content: content,
        name: "some name",
        description: to_rich_text("some description"),
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)

      assert {:ok, %{business_concept_version: business_concept_version}} =
               BusinessConcepts.create_business_concept(creation_attrs)

      assert business_concept_version.content == %{"Field1" => ["World", "World2"]}
      assert business_concept_version.name == version_attrs.name
      assert business_concept_version.description == version_attrs.description
      assert business_concept_version.last_change_by == version_attrs.last_change_by
      assert business_concept_version.current == true
      assert business_concept_version.in_progress == true
      assert business_concept_version.version == version_attrs.version
      assert business_concept_version.business_concept.type == concept_attrs.type
      assert business_concept_version.business_concept.domain_id == concept_attrs.domain_id

      assert business_concept_version.business_concept.last_change_by ==
               concept_attrs.last_change_by
    end

    test "with no content" do
      %{user_id: user_id} = build(:session)
      domain = insert(:domain)

      content_schema = [%{"name" => "Field1", "type" => "string", "cardinality" => "?"}]

      concept_attrs = %{
        type: "some_type",
        domain_id: domain.id,
        last_change_by: user_id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        name: "some name",
        description: to_rich_text("some description"),
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)

      assert {:error, :business_concept_version, %Ecto.Changeset{} = changeset, _} =
               BusinessConcepts.create_business_concept(creation_attrs)

      assert_expected_validation(changeset, "content", :required)
    end

    test "with nil content" do
      %{user_id: user_id} = build(:session)
      domain = insert(:domain)

      content_schema = [%{"name" => "Field1", "type" => "string", "cardinality" => "?"}]

      concept_attrs = %{
        type: "some_type",
        domain_id: domain.id,
        last_change_by: user_id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        content: nil,
        name: "some name",
        description: to_rich_text("some description"),
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)

      assert {:error, :business_concept_version, %Ecto.Changeset{} = changeset, _} =
               BusinessConcepts.create_business_concept(creation_attrs)

      assert_expected_validation(changeset, "content", :required)
    end

    test "with no content schema" do
      %{user_id: user_id} = build(:session)
      domain = insert(:domain)

      concept_attrs = %{
        type: "some_type",
        domain_id: domain.id,
        last_change_by: user_id,
        last_change_at: DateTime.utc_now()
      }

      creation_attrs = %{
        business_concept: concept_attrs,
        content: %{},
        name: "some name",
        description: to_rich_text("some description"),
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      assert_raise RuntimeError, "Content Schema is not defined for Business Concept", fn ->
        BusinessConcepts.create_business_concept(creation_attrs)
      end
    end
  end

  describe "update_business_concept_version/2" do
    test "updates the business_concept_version if data is valid" do
      %{user_id: user_id} = build(:session)
      business_concept_version = insert(:business_concept_version)

      concept_attrs = %{
        last_change_by: 1000,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        business_concept_id: business_concept_version.business_concept.id,
        content: %{},
        name: "updated name",
        description: to_rich_text("updated description"),
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      update_attrs = Map.put(version_attrs, :content_schema, [])

      assert {:ok, %BusinessConceptVersion{} = object} =
               BusinessConcepts.update_business_concept_version(
                 business_concept_version,
                 update_attrs
               )

      assert object.name == version_attrs.name
      assert object.description == version_attrs.description
      assert object.last_change_by == version_attrs.last_change_by
      assert object.current == true
      assert object.version == version_attrs.version
      assert object.in_progress == false

      assert object.business_concept.id == business_concept_version.business_concept.id
      assert object.business_concept.last_change_by == 1000
    end

    test "updates the content with valid content data" do
      content_schema = [
        %{"name" => "Field1", "type" => "string", "cardinality" => "1"},
        %{"name" => "Field2", "type" => "string", "cardinality" => "1"}
      ]

      %{user_id: user_id} = build(:session)

      content = %{
        "Field1" => "First field",
        "Field2" => "Second field"
      }

      business_concept_version =
        insert(:business_concept_version, last_change_by: user_id, content: content)

      update_content = %{
        "Field1" => "New first field"
      }

      concept_attrs = %{
        last_change_by: 1000,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        business_concept_id: business_concept_version.business_concept.id,
        content: update_content,
        name: "updated name",
        description: to_rich_text("updated description"),
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      update_attrs = Map.put(version_attrs, :content_schema, content_schema)

      assert {:ok, business_concept_version} =
               BusinessConcepts.update_business_concept_version(
                 business_concept_version,
                 update_attrs
               )

      assert %BusinessConceptVersion{} = business_concept_version
      assert business_concept_version.content["Field1"] == "New first field"
      assert business_concept_version.content["Field2"] == "Second field"
    end

    test "returns error and changeset if validation fails" do
      business_concept_version = insert(:business_concept_version)

      version_attrs = %{
        business_concept: nil,
        content: %{},
        name: nil,
        description: nil,
        last_change_by: nil,
        last_change_at: nil,
        version: nil
      }

      update_attrs = Map.put(version_attrs, :content_schema, [])

      assert {:error, :updated, %Ecto.Changeset{}, _} =
               BusinessConcepts.update_business_concept_version(
                 business_concept_version,
                 update_attrs
               )

      object =
        BusinessConcepts.get_last_version_by_business_concept_id!(
          business_concept_version.business_concept.id
        )

      assert object |> business_concept_version_preload() == business_concept_version
    end
  end

  describe "business_concepts" do
    @tag template: [
           %{
             "name" => "group",
             "fields" => [%{name: "fieldname", type: "string", cardinality: "?"}]
           }
         ]
    defp fixture do
      parent_domain = insert(:domain)
      child_domain = insert(:domain, parent: parent_domain)
      insert(:business_concept, type: @template_name, domain: child_domain)
      insert(:business_concept, type: @template_name, domain: parent_domain)
    end

    test "get_last_version_by_business_concept_id!/1 returns the business_concept with given id" do
      business_concept_version = insert(:business_concept_version)

      object =
        BusinessConcepts.get_last_version_by_business_concept_id!(
          business_concept_version.business_concept.id
        )

      assert object |> business_concept_version_preload() == business_concept_version
    end

    test "get_currently_published_version!/1 returns the published business_concept with given id" do
      %{id: business_concept_id} = insert(:business_concept)

      [_, _, published_id, _] =
        ["draft", "versioned", "published", "deprecated"]
        |> Enum.map(
          &insert(:business_concept_version, business_concept_id: business_concept_id, status: &1)
        )
        |> Enum.map(& &1.id)

      assert %{id: ^published_id} =
               BusinessConcepts.get_currently_published_version!(business_concept_id)
    end

    test "get_currently_published_version!/1 returns the last when there are no published" do
      bcv_draft = insert(:business_concept_version, status: "draft")

      bcv_current =
        BusinessConcepts.get_currently_published_version!(bcv_draft.business_concept.id)

      assert bcv_current.id == bcv_draft.id
    end

    test "check_business_concept_name_availability/2 check not available" do
      name = random_name()
      %{business_concept: %{type: type}} = insert(:business_concept_version, name: name)

      assert {:error, :name_not_available} ==
               BusinessConcepts.check_business_concept_name_availability(type, name)
    end

    test "check_business_concept_name_availability/2 check available" do
      name = random_name()

      %{business_concept: %{id: exclude_concept_id, type: type}} =
        insert(:business_concept_version, name: name)

      assert BusinessConcepts.check_business_concept_name_availability(
               type,
               name,
               business_concept_id: exclude_concept_id
             ) == :ok
    end

    test "check_business_concept_name_availability/3 check not available" do
      assert [%{name: name}, %{business_concept: %{id: exclude_id, type: type}}] =
               1..10
               |> Enum.map(fn _ -> random_name() end)
               |> Enum.uniq()
               |> Enum.take(2)
               |> Enum.map(&insert(:business_concept_version, name: &1))

      assert {:error, :name_not_available} ==
               BusinessConcepts.check_business_concept_name_availability(type, name,
                 business_concept_id: exclude_id
               )
    end

    test "count_published_business_concepts/2 check count" do
      %{business_concept: %{id: id, type: type}} =
        insert(:business_concept_version, status: "published")

      assert 1 == BusinessConcepts.count_published_business_concepts(type, [id])
    end

    test "list_all_business_concepts/0 return all business_concetps" do
      fixture()
      assert length(BusinessConcepts.list_all_business_concepts()) == 2
    end

    test "load_business_concept/1 return the expected business_concept" do
      business_concept = fixture()
      assert business_concept.id == BusinessConcepts.get_business_concept!(business_concept.id).id
    end
  end

  describe "business_concept_versions" do
    test "list_all_business_concept_versions/0 returns all business_concept_versions" do
      business_concept_version = insert(:business_concept_version)
      business_concept_versions = BusinessConcepts.list_all_business_concept_versions()

      assert business_concept_versions
             |> Enum.map(fn b -> business_concept_version_preload(b) end) ==
               [business_concept_version]
    end

    test "list_business_concept_versions/1 returns all business_concept_versions of a business_concept_version" do
      business_concept_version = insert(:business_concept_version)
      business_concept_id = business_concept_version.business_concept.id

      business_concept_versions =
        BusinessConcepts.list_business_concept_versions(business_concept_id, [
          "draft"
        ])

      assert business_concept_versions
             |> Enum.map(fn b -> business_concept_version_preload(b) end) ==
               [business_concept_version]
    end

    test "get_business_concept_version!/1 returns the business_concept_version with given id" do
      %{id: id} = insert(:business_concept_version)
      assert %BusinessConceptVersion{id: ^id} = BusinessConcepts.get_business_concept_version!(id)
    end

    test "get_confidential_ids returns all business concept ids which are confidential" do
      bc1 = insert(:business_concept, confidential: true)
      bc2 = insert(:business_concept)
      bc3 = insert(:business_concept)

      insert(:business_concept_version,
        name: "bcv1",
        business_concept: bc1
      )

      insert(:business_concept_version,
        name: "bcv2",
        business_concept: bc2
      )

      insert(:business_concept_version, name: "bcv3", business_concept: bc3)

      assert BusinessConcepts.get_confidential_ids() == [bc1.id]
    end

    @tag template: [
           %{
             "name" => "group",
             "fields" => [
               %{
                 "name" => "multiple_1",
                 "type" => "string",
                 "group" => "Multiple Group",
                 "label" => "Multiple 1",
                 "values" => %{
                   "fixed" => ["1", "2", "3", "4", "5"]
                 },
                 "widget" => "dropdown",
                 "cardinality" => "*"
               }
             ]
           }
         ]
    test "search_fields/1 returns a business_concept_version with default values in its content" do
      alias Elasticsearch.Document

      business_concept = insert(:business_concept, type: @template_name)

      business_concept_version =
        insert(:business_concept_version, business_concept: business_concept)

      %{template: template, content: content} = Document.encode(business_concept_version)

      assert Map.get(template, :name) == @template_name
      assert Map.get(content, "multiple_1") == [""]
    end
  end

  defp concept_taxonomy(_) do
    parent_id = fn
      1 -> nil
      id -> id - 1
    end

    domains =
      Enum.map(
        1..5,
        &insert(:domain,
          id: &1,
          parent_id: parent_id.(&1)
        )
      )

    concept =
      insert(:business_concept_version,
        business_concept: insert(:business_concept, domain: List.last(domains))
      )

    Enum.each(domains, &DomainLoader.refresh(&1.id))

    on_exit(fn -> Enum.each(domains, &DomainLoader.delete(&1.id)) end)
    [concept: concept, domains: domains]
  end

  describe "add_parents/1" do
    setup [:concept_taxonomy]

    test "add_parents/1 gets concept taxonomy", %{concept: concept, domains: parents} do
      parents =
        parents
        |> Enum.reverse()
        |> Enum.map(&Map.take(&1, [:external_id, :id, :name]))

      assert %{domain_parents: ^parents} = BusinessConcepts.add_parents(concept)
    end
  end

  test "with invalid content: required" do
    %{user_id: user_id} = build(:session)
    domain = insert(:domain)

    content_schema = [
      %{
        "name" => "data_owner",
        "type" => "user",
        "group" => "New Group 1",
        "label" => "data_owner",
        "values" => %{"role_users" => "data_owner", "processed_users" => []},
        "widget" => "dropdown",
        "cardinality" => "1"
      },
      %{
        "name" => "texto_libre",
        "type" => "enriched_text",
        "group" => "New Group 1",
        "label" => "texto libre",
        "widget" => "enriched_text",
        "cardinality" => "1"
      },
      %{
        "name" => "link",
        "type" => "url",
        "group" => "New Group 1",
        "label" => "link",
        "widget" => "pair_list",
        "cardinality" => "+"
      },
      %{
        "name" => "lista",
        "type" => "string",
        "group" => "New Group 1",
        "label" => "lista",
        "values" => %{"fixed_tuple" => [%{"text" => "valor1", "value" => "codigo1"}]},
        "widget" => "dropdown",
        "cardinality" => "+"
      }
    ]

    content = %{
      "data_owner" => "domain",
      "link" => "https://google.es",
      "lista" => "valor1",
      "texto_libre" => "free text"
    }

    concept_attrs = %{
      type: "some_type",
      domain_id: domain.id,
      last_change_by: user_id,
      last_change_at: DateTime.utc_now()
    }

    version_attrs = %{
      business_concept: concept_attrs,
      content: content,
      name: "some name",
      description: RichText.to_rich_text("some description"),
      last_change_by: user_id,
      last_change_at: DateTime.utc_now(),
      version: 1
    }

    creation_attrs = Map.put(version_attrs, :content_schema, content_schema)

    assert {:ok, %{business_concept_version: business_concept_version}} =
             BusinessConcepts.create_business_concept(creation_attrs)

    assert business_concept_version.content == %{
             "data_owner" => "domain",
             "link" => [
               %{
                 "url_name" => "https://google.es",
                 "url_value" => "https://google.es"
               }
             ],
             "lista" => ["codigo1"],
             "texto_libre" => RichText.to_rich_text("free text")
           }

    assert business_concept_version.name == version_attrs.name
    assert business_concept_version.description == version_attrs.description
    assert business_concept_version.last_change_by == version_attrs.last_change_by
    assert business_concept_version.current == true
    assert business_concept_version.in_progress == false
    assert business_concept_version.version == version_attrs.version
    assert business_concept_version.business_concept.type == concept_attrs.type
    assert business_concept_version.business_concept.domain_id == concept_attrs.domain_id

    assert business_concept_version.business_concept.last_change_by ==
             concept_attrs.last_change_by
  end

  test "count/1 returns business concept count for a domain" do
    %{domain_id: domain_id} = concept = insert(:business_concept, domain: build(:domain))
    insert(:business_concept_version, business_concept: concept, current: true)

    insert(:business_concept_version,
      business_concept: concept,
      current: true,
      status: "deprecated"
    )

    insert(:business_concept_version, business_concept: concept, current: false)

    assert BusinessConcepts.count(domain_id: domain_id, deprecated: false) == 1
  end

  defp to_rich_text(plain) do
    %{"document" => plain}
  end

  defp business_concept_version_preload(business_concept_version) do
    business_concept_version
    |> Repo.preload(:business_concept)
    |> Repo.preload(business_concept: [:domain])
  end

  defp assert_expected_validation(changeset, field, expected_validation) do
    find_def = {:unknown, {"", [validation: :unknown]}}

    current_validation =
      changeset.errors
      |> Enum.find(find_def, fn {key, _value} ->
        key == String.to_atom(field)
      end)
      |> elem(1)
      |> elem(1)
      |> Keyword.get(:validation)

    assert current_validation == expected_validation
    changeset
  end

  defp random_name do
    id = :rand.uniform(100_000_000)
    "Concept #{id}"
  end
end
