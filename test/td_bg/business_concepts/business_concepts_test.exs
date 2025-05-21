defmodule TdBg.BusinessConceptsTest do
  use TdBg.DataCase

  import Assertions
  import Mox

  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.BusinessConcepts.Workflow
  alias TdBg.I18nContents.I18nContents
  alias TdBg.Repo
  alias TdCache.I18nCache
  alias TdCache.Redix
  alias TdCache.Redix.Stream
  alias TdCluster.TestHelpers.TdAiMock.Embeddings
  alias TdCore.Search.IndexWorkerMock
  alias TdDfLib.Format
  alias TdDfLib.RichText

  @stream TdCache.Audit.stream()
  @template_name "TestTemplate1234"

  @content [
    %{
      "name" => "group",
      "fields" => [
        %{
          name: "foo",
          type: "string",
          cardinality: "?",
          values: %{"fixed" => ["bar"]},
          subscribable: true
        },
        %{
          name: "xyz",
          type: "string",
          cardinality: "?",
          values: %{"fixed" => ["foo"]}
        }
      ]
    }
  ]

  @content_with_mandatory_fields [
    %{
      "name" => "group",
      "fields" => [
        %{
          name: "Field1",
          type: "string",
          cardinality: "1",
          values: nil,
          subscribable: true,
          label: "Field1"
        },
        %{
          name: "Field2",
          type: "string",
          cardinality: "1",
          values: nil,
          subscribable: true,
          label: "Field2"
        },
        %{
          name: "Field3",
          type: "string",
          cardinality: "+",
          values: nil,
          subscribable: true,
          label: "Field3"
        }
      ]
    }
  ]

  @i18n_content [
    %{
      "name" => "group",
      "fields" => [
        %{
          name: "i18n",
          type: "string",
          label: "label_i18n",
          cardinality: "1",
          values: %{"fixed" => ["one", "two", "three"]},
          subscribable: true
        }
      ]
    }
  ]

  @table_content [
    %{
      "name" => "group",
      "fields" => [
        %{
          name: "table_field",
          type: "table",
          label: "Table Field",
          cardinality: "*",
          subscribable: false,
          values: %{
            "table_columns" => [
              %{"mandatory" => true, "name" => "First Column"},
              %{"mandatory" => false, "name" => "Second Column"},
              %{"mandatory" => true, "name" => "Third Column"}
            ]
          }
        }
      ]
    }
  ]

  @content_with_identifier [
    %{
      "name" => "group",
      "fields" => [
        %{
          name: "mandatory_string",
          type: "string",
          label: "Mandatory String",
          cardinality: "1",
          subscribable: false
        },
        %{
          name: "indentifier",
          type: "string",
          widget: "identifier",
          cardinality: "0",
          values: nil,
          subscribable: false
        }
      ]
    }
  ]

  setup_all do
    Redix.del!(@stream)
    TdCache.Redix.del!("i18n:locales:*")
    start_supervised!(TdBg.Cache.ConceptLoader)
    start_supervised!(TdBg.Cache.DomainLoader)
    :ok
  end

  setup context do
    on_exit(fn ->
      Redix.del!(@stream)
      IndexWorkerMock.clear()
    end)

    case context[:template] do
      nil ->
        :ok

      content ->
        %{id: template_id} =
          Templates.create_template(%{
            id: 0,
            name: @template_name,
            label: "label",
            scope: "test",
            content: content
          })

        on_exit(fn ->
          Templates.delete(template_id)
        end)
    end

    :ok
  end

  setup :set_mox_from_context
  setup :verify_on_exit!

  describe "create_business_concept/1" do
    @tag template: @content
    test "with valid data creates a business_concept and publishes an event including subscribable fields to the audit stream " do
      %{user_id: user_id} = build(:claims)
      domain = insert(:domain)

      concept_attrs = %{
        type: @template_name,
        domain_id: domain.id,
        last_change_by: user_id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        content: %{
          "foo" => %{"value" => "bar", "origin" => "user"},
          "xyz" => %{"value" => "foo", "origin" => "user"}
        },
        name: "some name",
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      content_schema = TdDfLib.Templates.content_schema(@template_name)
      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)

      assert {:ok, %{business_concept_version: business_concept_version, audit: [event_id]}} =
               BusinessConcepts.create_business_concept(creation_attrs)

      assert business_concept_version.content == version_attrs.content
      assert business_concept_version.name == version_attrs.name

      assert business_concept_version.last_change_by == version_attrs.last_change_by
      assert business_concept_version.current == true
      assert business_concept_version.version == version_attrs.version
      assert business_concept_version.in_progress == false
      assert business_concept_version.business_concept.type == concept_attrs.type
      assert business_concept_version.business_concept.domain_id == concept_attrs.domain_id

      assert business_concept_version.business_concept.last_change_by ==
               concept_attrs.last_change_by

      assert {:ok, [%{event: event, payload: payload, id: ^event_id}]} =
               Stream.read(:redix, @stream, transform: true)

      assert event == "new_concept_draft"

      assert %{"subscribable_fields" => %{"foo" => %{"value" => "bar", "origin" => "user"}}} =
               Jason.decode!(payload)
    end

    test "with invalid data returns error changeset" do
      version_attrs = %{
        business_concept: nil,
        content: %{},
        name: nil,
        last_change_by: nil,
        last_change_at: nil,
        version: nil
      }

      creation_attrs = Map.put(version_attrs, :content_schema, [])

      assert {:error, :business_concept_version, %Ecto.Changeset{}, _} =
               BusinessConcepts.create_business_concept(creation_attrs)
    end

    @tag template: @content
    test "with content" do
      %{user_id: user_id} = build(:claims)
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

      content = %{
        "Field1" => %{"value" => "Hello", "origin" => "user"},
        "Field2" => %{"value" => "World", "origin" => "user"},
        "Field3" => %{"value" => ["Hellow", "World"], "origin" => "user"}
      }

      concept_attrs = %{
        type: @template_name,
        domain_id: domain.id,
        last_change_by: user_id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        content: content,
        name: "some name",
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)

      assert {:ok, %{business_concept_version: business_concept_version}} =
               BusinessConcepts.create_business_concept(creation_attrs)

      assert %{content: ^content} = business_concept_version
    end

    @tag template: @content
    test "with i18n_content" do
      %{user_id: user_id} = build(:claims)
      domain = insert(:domain)
      I18nCache.put_required_locales(["es"])

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

      content = %{
        "Field1" => %{"value" => "Hello", "origin" => "user"},
        "Field2" => %{"value" => "World", "origin" => "user"},
        "Field3" => %{"value" => "Hellow", "origin" => "user"}
      }

      es_content = %{
        "Field1" => %{"value" => "Hola", "origin" => "user"},
        "Field3" => %{"value" => "Hola", "origin" => "user"}
      }

      concept_attrs = %{
        type: @template_name,
        domain_id: domain.id,
        last_change_by: user_id,
        last_change_at: DateTime.utc_now()
      }

      creation_attrs = %{
        business_concept: concept_attrs,
        content: content,
        name: "some name",
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1,
        content_schema: content_schema,
        i18n_content: %{"es" => %{"name" => "es_name", "content" => es_content}}
      }

      assert {:ok, %{i18n_content: {1, [%{name: "es_name", content: ^es_content}]}}} =
               BusinessConcepts.create_business_concept(creation_attrs)
    end

    @tag template: @content_with_mandatory_fields
    test "with invalid content: required" do
      %{user_id: user_id} = build(:claims)
      domain = insert(:domain)

      content = %{
        "Field1" => %{"value" => "Hola", "origin" => "default"},
        "Field2" => %{"value" => "", "origin" => "default"},
        "Field3" => %{"value" => [], "origin" => "default"}
      }

      version_attrs = %{
        business_concept: %{
          type: @template_name,
          domain_id: domain.id,
          last_change_by: user_id,
          last_change_at: DateTime.utc_now()
        },
        content: content,
        name: "some name",
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1,
        content_schema: []
      }

      assert {:ok, %{business_concept_version: business_concept_version}} =
               BusinessConcepts.create_business_concept(version_attrs)

      assert business_concept_version.content == version_attrs.content
      assert business_concept_version.name == version_attrs.name
      assert business_concept_version.last_change_by == version_attrs.last_change_by
      assert business_concept_version.current == true
      assert business_concept_version.in_progress == true
      assert business_concept_version.version == version_attrs.version
      assert business_concept_version.business_concept.type == version_attrs.business_concept.type

      assert business_concept_version.business_concept.domain_id ==
               version_attrs.business_concept.domain_id

      assert business_concept_version.business_concept.last_change_by ==
               version_attrs.business_concept.last_change_by
    end

    @tag template: @content_with_mandatory_fields
    test "with invalid content: invalid variable list" do
      %{user_id: user_id} = build(:claims)
      domain = insert(:domain)

      content_schema = [
        %{"name" => "Field1", "type" => "string", "cardinality" => "1"}
      ]

      content = %{"Field1" => %{"value" => ["World", "World2"], "origin" => "user"}}

      concept_attrs = %{
        type: @template_name,
        domain_id: domain.id,
        last_change_by: user_id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        content: content,
        name: "some name",
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      creation_attrs = Map.put(version_attrs, :content_schema, content_schema)

      assert {:error, :business_concept_version, %{valid?: false, errors: errors}, %{}} =
               BusinessConcepts.create_business_concept(creation_attrs)

      assert {_message, fields} = errors[:content]

      assert fields[:Field2] == {"can't be blank", [validation: :required]}
      assert fields[:Field1] == {"is invalid", [type: :string, validation: :cast]}
    end

    test "with no content" do
      %{user_id: user_id} = build(:claims)
      domain = insert(:domain)

      content_schema = [
        %{"name" => "Field1", "type" => "string", "cardinality" => "?"}
      ]

      concept_attrs = %{
        type: "some_type",
        domain_id: domain.id,
        last_change_by: user_id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        name: "some name",
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
      %{user_id: user_id} = build(:claims)
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
      %{user_id: user_id} = build(:claims)
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
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      assert_raise RuntimeError, "Content Schema is not defined for Business Concept", fn ->
        BusinessConcepts.create_business_concept(creation_attrs)
      end
    end

    @tag template: @i18n_content
    test "with content including invalid i18n value returns validation error" do
      %{user_id: user_id} = build(:claims)
      domain = insert(:domain)

      content_schema = [
        %{
          "cardinality" => "1",
          "label" => "label_i18n",
          "name" => "i18n",
          "type" => "string",
          "values" => %{"fixed" => ["one", "two", "three"]}
        }
      ]

      content = %{"i18n" => %{"value" => "uno", "origin" => "user"}}

      concept_attrs = %{
        type: @template_name,
        domain_id: domain.id,
        last_change_by: user_id,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        content: content,
        name: "some name",
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      creation_attrs =
        version_attrs
        |> Map.put(:content_schema, content_schema)
        |> Map.put(:lang, "es")

      assert {:error, :business_concept_version, %{errors: errors}, _} =
               BusinessConcepts.create_business_concept(creation_attrs, in_progress: false)

      assert {"i18n: is invalid",
              [i18n: {"is invalid", [validation: :inclusion, enum: ["one", "two", "three"]]}]} ==
               errors[:content]
    end

    @tag template: @table_content
    test "sets concept in progress when table field has blank columns" do
      %{user_id: user_id} = build(:claims)
      domain = insert(:domain)

      attrs = %{
        business_concept: %{
          type: @template_name,
          domain_id: domain.id,
          last_change_by: user_id,
          last_change_at: DateTime.utc_now()
        },
        content: %{
          "table_field" => %{
            "origin" => "user",
            "value" => [
              %{"First Column" => nil, "Second Column" => "Bar"},
              %{"First Column" => "Foo", "Second Column" => "Bar"},
              %{"Second Column" => "Bar"},
              %{"First Column" => "", "Second Column" => "Bar"}
            ]
          }
        },
        name: "some name",
        content_schema: [],
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      # when in_progress: false => content is validated
      assert {:error, :business_concept_version, changeset, %{}} =
               BusinessConcepts.create_business_concept(attrs, in_progress: false)

      assert {_message, content_errors} = changeset.errors[:content]

      assert Enum.count(content_errors) == 2

      for {:table_field, error} <- content_errors do
        {message, validation} = error

        case message do
          "First Column can't be blank" ->
            assert validation == [validation: :required, rows: [0, 2, 3]]

          "Third Column can't be blank" ->
            assert validation == [validation: :required, rows: [0, 1, 2, 3]]
        end
      end

      # set in progress as default bahvior
      assert {:ok, %{audit: _audit, business_concept_version: version}} =
               BusinessConcepts.create_business_concept(attrs)

      assert version.in_progress

      assert version.content == %{
               "table_field" => %{
                 "origin" => "user",
                 "value" => [
                   %{"First Column" => nil, "Second Column" => "Bar"},
                   %{"First Column" => "Foo", "Second Column" => "Bar"},
                   %{"Second Column" => "Bar"},
                   %{"First Column" => "", "Second Column" => "Bar"}
                 ]
               }
             }
    end

    @tag template: @content_with_identifier
    test "identifier field generated in content" do
      %{user_id: user_id} = build(:claims)
      domain = insert(:domain)

      attrs = %{
        business_concept: %{
          type: @template_name,
          domain_id: domain.id,
          last_change_by: user_id,
          last_change_at: DateTime.utc_now()
        },
        content: %{},
        name: "name",
        content_schema: [],
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      # returns changeset with identifier when concept is in progress
      {:ok, %{business_concept_version: version}} =
        BusinessConcepts.create_business_concept(attrs)

      assert version.in_progress
      assert get_in(version.content, ["indentifier", "value"])

      content = %{"mandatory_string" => %{"origin" => "user", "value" => "foo"}}

      attrs =
        attrs
        |> Map.put(:content, content)
        |> Map.put(:name, "updated")

      # returns changeset with identifier when concept is not in progress
      {:ok, %{business_concept_version: version}} =
        BusinessConcepts.create_business_concept(attrs)

      refute version.in_progress
      assert get_in(version.content, ["indentifier", "value"])
    end

    @tag template: @content_with_identifier
    test "identifier field generated in i18n content" do
      %{user_id: user_id} = build(:claims)
      domain = insert(:domain)

      attrs = %{
        business_concept: %{
          type: @template_name,
          domain_id: domain.id,
          last_change_by: user_id,
          last_change_at: DateTime.utc_now()
        },
        content: %{},
        i18n_content: %{
          "es" => %{
            "name" => "nombre",
            "content" => %{}
          }
        },
        name: "name",
        content_schema: [],
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      # returns source changeset without merging with i18n content
      {:ok, %{business_concept_version: version}} =
        BusinessConcepts.create_business_concept(attrs)

      assert version.in_progress
      assert get_in(version.content, ["indentifier", "value"])

      content = %{"mandatory_string" => %{"origin" => "user", "value" => "foo"}}

      attrs =
        attrs
        |> Map.put(:content, content)
        |> put_in([:i18n_content, "es", "content"], content)
        |> Map.put(:name, "updated")

      # gets default i18n changeset when there are not failures
      {:ok, %{business_concept_version: version}} =
        BusinessConcepts.create_business_concept(attrs)

      refute version.in_progress
      assert get_in(version.content, ["indentifier", "value"])
    end
  end

  describe "update_business_concept_version/2" do
    @tag template: @content
    test "updates the business_concept_version if data is valid and publishes an event to the audit stream" do
      IndexWorkerMock.clear()
      %{user_id: user_id} = build(:claims)

      %{id: parent_id, parent_id: root_id} = parent = insert(:domain, parent: build(:domain))
      %{id: domain_id} = domain = insert(:domain, parent_id: parent_id)

      Enum.each([parent.parent, parent, domain], &CacheHelpers.put_domain/1)

      concept = build(:business_concept, domain_id: domain_id, type: @template_name)

      business_concept_version =
        insert(:business_concept_version,
          business_concept: concept,
          content: %{
            "foo" => %{"value" => "bar", "origin" => "user"},
            "xyz" => %{"value" => "foo", "origin" => "user"}
          }
        )

      concept_attrs = %{
        last_change_by: 1000,
        last_change_at: DateTime.utc_now()
      }

      version_attrs = %{
        business_concept: concept_attrs,
        business_concept_id: business_concept_version.business_concept.id,
        content: %{
          "foo" => %{"value" => "bar", "origin" => "user"},
          "xyz" => %{"value" => "foo", "origin" => "user"}
        },
        name: "updated name",
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      content_schema = TdDfLib.Templates.content_schema(@template_name)
      update_attrs = Map.put(version_attrs, :content_schema, content_schema)

      assert {:ok, %BusinessConceptVersion{} = object} =
               BusinessConcepts.update_business_concept_version(
                 business_concept_version,
                 update_attrs
               )

      assert object.name == version_attrs.name
      assert object.last_change_by == version_attrs.last_change_by
      assert object.current == true
      assert object.version == version_attrs.version
      assert object.in_progress == false

      assert object.business_concept.id == business_concept_version.business_concept.id
      assert object.business_concept.last_change_by == 1000

      assert {:ok, [%{payload: payload}]} = Stream.read(:redix, @stream, transform: true)

      assert %{
               "subscribable_fields" => %{"foo" => %{"value" => "bar", "origin" => "user"}},
               "domain_ids" => domain_ids
             } = Jason.decode!(payload)

      assert_lists_equal(domain_ids, [root_id, parent_id, domain_id])
      assert [{:reindex, :concepts, [_]}] = IndexWorkerMock.calls()
      IndexWorkerMock.clear()
    end

    test "updates the content with valid content data" do
      IndexWorkerMock.clear()
      %{id: domain_id} = insert(:domain)

      template_name = "test_template"

      content_schema = [
        %{
          "name" => "group",
          "fields" => [
            %{
              "name" => "Field1",
              "type" => "string",
              "cardinality" => "1",
              "default" => %{"value" => "", "origin" => "user"}
            },
            %{
              "name" => "Field2",
              "type" => "string",
              "cardinality" => "?",
              "default" => %{"value" => "", "origin" => "user"}
            }
          ]
        }
      ]

      template = %{
        id: 0,
        name: template_name,
        label: "label",
        scope: "test",
        content: content_schema
      }

      Templates.create_template(template)

      %{user_id: user_id} = build(:claims)

      content = %{
        "Field1" => %{"value" => "First field", "origin" => "user"},
        "Field2" => %{"value" => "Second field", "origin" => "user"}
      }

      concept_attrs = %{
        type: template_name,
        domain_id: domain_id,
        last_change_by: 1000,
        last_change_at: DateTime.utc_now()
      }

      business_concept = insert(:business_concept, concept_attrs)

      business_concept_version =
        insert(:business_concept_version,
          business_concept: business_concept,
          last_change_by: user_id,
          content: content
        )

      update_content = %{
        "Field1" => %{"value" => "New first field", "origin" => "user"}
      }

      version_attrs = %{
        business_concept: concept_attrs,
        business_concept_id: business_concept_version.business_concept.id,
        content: update_content,
        name: "updated name",
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      update_attrs =
        Map.put(version_attrs, :content_schema, Format.flatten_content_fields(content_schema))

      assert {:ok, new_business_concept_version} =
               BusinessConcepts.update_business_concept_version(
                 business_concept_version,
                 update_attrs
               )

      assert %BusinessConceptVersion{} = new_business_concept_version

      assert new_business_concept_version.content["Field1"] == %{
               "value" => "New first field",
               "origin" => "user"
             }

      assert Map.get(new_business_concept_version.content, "Field2") == nil

      assert [{:reindex, :concepts, [_]}] = IndexWorkerMock.calls()
      IndexWorkerMock.clear()
    end

    test "updates the content with valid i18n_content data" do
      %{id: domain_id} = insert(:domain)

      template_name = "test_template"

      content_schema = [
        %{
          "name" => "group",
          "fields" => [
            %{
              "name" => "Field1",
              "type" => "string",
              "cardinality" => "1",
              "default" => %{"value" => "", "origin" => "default"}
            },
            %{
              "name" => "Field2",
              "type" => "string",
              "cardinality" => "?",
              "default" => %{"value" => "", "origin" => "default"}
            }
          ]
        }
      ]

      template = %{
        id: 0,
        name: template_name,
        label: "label",
        scope: "test",
        content: content_schema
      }

      Templates.create_template(template)

      %{user_id: user_id} = build(:claims)

      concept_attrs = %{
        type: template_name,
        domain_id: domain_id,
        last_change_by: 1000,
        last_change_at: DateTime.utc_now()
      }

      content = %{
        "Field1" => %{"value" => "First field", "origin" => "user"},
        "Field2" => %{"value" => "Second field", "origin" => "user"}
      }

      %{id: bcv_id, name: name} =
        business_concept_version =
        insert(:business_concept_version,
          business_concept: insert(:business_concept, concept_attrs),
          last_change_by: user_id,
          content: content
        )

      en_lang = "en"
      en_name = "#{en_lang}_#{name}"
      fr_lang = "fr"
      fr_name = "#{fr_lang}_#{name}"

      insert(:i18n_content,
        business_concept_version_id: bcv_id,
        name: en_name,
        lang: en_lang,
        content: content
      )

      update_content = %{
        "Field1" => %{"value" => "New first field", "origin" => "user"}
      }

      update_attrs = %{
        business_concept: concept_attrs,
        content: update_content,
        content_schema: Format.flatten_content_fields(content_schema),
        i18n_content: %{
          en_lang => %{"name" => en_name, "content" => update_content},
          fr_lang => %{"name" => fr_name, "content" => content}
        }
      }

      assert {:ok, _} =
               BusinessConcepts.update_business_concept_version(
                 business_concept_version,
                 update_attrs
               )

      assert [i18n_response_1, i18n_response_2] =
               bcv_id
               |> I18nContents.get_all_i18n_content_by_bcv_id()
               |> Enum.sort_by(& &1.lang)

      assert i18n_response_1.content["Field1"] == %{
               "value" => "New first field",
               "origin" => "user"
             }

      assert Map.get(i18n_response_1.content, "Field2") == nil
      assert i18n_response_1.lang == en_lang
      assert i18n_response_1.name == en_name

      assert i18n_response_2.content["Field1"] == %{"value" => "First field", "origin" => "user"}
      assert i18n_response_2.content["Field2"] == %{"value" => "Second field", "origin" => "user"}
      assert i18n_response_2.lang == fr_lang
      assert i18n_response_2.name == fr_name
    end

    test "returns error and changeset if validation fails" do
      business_concept_version = insert(:business_concept_version)

      version_attrs = %{
        business_concept: nil,
        content: %{},
        name: nil,
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

    @tag template: @content_with_mandatory_fields
    test "updates content a sets in progress as false when concept is valid" do
      %{user_id: user_id} = build(:claims)

      %{id: domain_id} = insert(:domain)

      concept = build(:business_concept, domain_id: domain_id, type: @template_name)

      business_concept_version =
        insert(:business_concept_version,
          business_concept: concept,
          in_progress: true,
          content: %{
            "Field1" => %{"value" => "bar", "origin" => "user"}
          }
        )

      version_attrs = %{
        business_concept: %{
          last_change_by: 1000,
          last_change_at: DateTime.utc_now()
        },
        business_concept_id: business_concept_version.business_concept.id,
        content: %{
          "Field1" => %{"value" => "bar", "origin" => "user"},
          "Field2" => %{"value" => "foo", "origin" => "user"},
          "Field3" => %{"value" => ["baz"], "origin" => "user"}
        },
        name: "updated name",
        last_change_by: user_id,
        last_change_at: DateTime.utc_now(),
        version: 1
      }

      content_schema = TdDfLib.Templates.content_schema(@template_name)
      update_attrs = Map.put(version_attrs, :content_schema, content_schema)

      assert business_concept_version.in_progress

      assert {:ok, %BusinessConceptVersion{} = object} =
               BusinessConcepts.update_business_concept_version(
                 business_concept_version,
                 update_attrs
               )

      assert object.content == %{
               "Field1" => %{"origin" => "user", "value" => "bar"},
               "Field2" => %{"origin" => "user", "value" => "foo"},
               "Field3" => %{"origin" => "user", "value" => ["baz"]}
             }

      assert object.name == version_attrs.name
      assert object.last_change_by == version_attrs.last_change_by
      assert object.current == true
      assert object.version == version_attrs.version
      assert object.in_progress == false

      assert object.business_concept.id == business_concept_version.business_concept.id
      assert object.business_concept.last_change_by == 1000
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

    test "load_business_concept/1 return the expected business_concept" do
      business_concept = fixture()
      assert business_concept.id == BusinessConcepts.get_business_concept(business_concept.id).id
    end
  end

  describe "business_concept_versions" do
    test "list_all_business_concept_versions/0 returns all business_concept_versions" do
      business_concept_version = insert(:business_concept_version)
      business_concept_versions = BusinessConcepts.list_all_business_concept_versions()

      assert business_concept_versions
             |> Enum.map(fn b -> business_concept_version_preload(b) end) ==
               [business_concept_version_preload(business_concept_version, [:domain, :shared_to])]
    end

    test "get_business_concept_version!/1 returns the business_concept_version with given id" do
      d1 = insert(:domain)
      d2 = %{id: domain_id2} = insert(:domain)
      d3 = %{id: domain_id3} = insert(:domain)

      concept = insert(:business_concept, domain: d1)
      insert(:shared_concept, business_concept: concept, domain: d2)
      insert(:shared_concept, business_concept: concept, domain: d3)

      %{id: id} = insert(:business_concept_version, business_concept: concept)

      assert %BusinessConceptVersion{
               id: ^id,
               business_concept: %{shared_to: [%{id: ^domain_id2}, %{id: ^domain_id3}]}
             } = BusinessConcepts.get_business_concept_version!(id)
    end

    test "get_business_concept_version!/1 with preloaded shared_to" do
      %{id: id} = insert(:business_concept_version)
      assert %BusinessConceptVersion{id: ^id} = BusinessConcepts.get_business_concept_version!(id)
    end

    @tag template: @content
    test "get_business_concept_version/2 returns the business_concept_version by concept id and version" do
      IndexWorkerMock.clear()
      claims = build(:claims)
      %{id: domain_id} = insert(:domain)

      %{id: business_concept_id} =
        business_concept = insert(:business_concept, type: @template_name, domain_id: domain_id)

      %{id: id, version: version} =
        bv1 = insert(:business_concept_version, business_concept: business_concept)

      assert %BusinessConceptVersion{id: ^id, version: ^version} =
               BusinessConcepts.get_business_concept_version(business_concept_id, "current")

      assert %BusinessConceptVersion{id: ^id, version: ^version} =
               BusinessConcepts.get_business_concept_version(business_concept_id, id)

      assert {:ok, %{updated: bv2}} = Workflow.submit_business_concept_version(bv1, claims)

      assert %BusinessConceptVersion{id: ^id, version: ^version} =
               BusinessConcepts.get_business_concept_version(business_concept_id, "current")

      assert {:ok, %{published: %{id: id} = bv3}} = Workflow.publish(bv2, claims)

      assert %BusinessConceptVersion{id: ^id, version: ^version} =
               BusinessConcepts.get_business_concept_version(business_concept_id, "current")

      assert {:ok, %{current: bv4}} = Workflow.new_version(bv3, claims)

      assert %BusinessConceptVersion{id: ^id, version: ^version} =
               BusinessConcepts.get_business_concept_version(business_concept_id, "current")

      %{id: id, version: version} = Map.take(bv4, [:id, :version])

      assert %BusinessConceptVersion{id: ^id, version: ^version} =
               BusinessConcepts.get_business_concept_version(business_concept_id, id)

      refute BusinessConcepts.get_business_concept_version(business_concept_id + 1, id)

      assert [_, _, _] = IndexWorkerMock.calls()
      IndexWorkerMock.clear()
    end

    test "get_business_concept_version/2 returns preloads" do
      d1 = %{id: domain_id1} = insert(:domain)
      d2 = %{id: domain_id2} = insert(:domain)
      d3 = %{id: domain_id3} = insert(:domain)

      concept = %{id: concept_id} = insert(:business_concept, domain: d1)
      insert(:shared_concept, business_concept: concept, domain: d2)
      insert(:shared_concept, business_concept: concept, domain: d3)

      %{id: id} = insert(:business_concept_version, business_concept: concept)

      assert %{
               id: ^id,
               business_concept: %{
                 id: ^concept_id,
                 domain: %{id: ^domain_id1},
                 shared_to: [%{id: ^domain_id2}, %{id: ^domain_id3}]
               }
             } = BusinessConcepts.get_business_concept_version(concept_id, id)
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

    @tag template: @content
    test "create new bc version with i18n_content" do
      claims = build(:claims)
      %{id: domain_id} = insert(:domain)

      business_concept = insert(:business_concept, type: @template_name, domain_id: domain_id)

      %{id: id} = bv1 = insert(:business_concept_version, business_concept: business_concept)

      %{lang: lang, content: content} = insert(:i18n_content, business_concept_version_id: id)

      assert {:ok, %{updated: bv2}} = Workflow.submit_business_concept_version(bv1, claims)

      assert {:ok, %{published: bv3}} = Workflow.publish(bv2, claims)

      assert {:ok, %{current: %{id: versioned_id}}} = Workflow.new_version(bv3, claims)

      assert [%{business_concept_version_id: ^versioned_id, lang: ^lang, content: ^content}] =
               I18nContents.get_all_i18n_content_by_bcv_id(versioned_id)
    end
  end

  describe "get_concept_counts/1" do
    test "includes link count and link tags" do
      %{business_concept_id: id, business_concept: concept} =
        bcv = insert(:business_concept_version)

      CacheHelpers.put_concept(concept, bcv)
      %{id: data_structure_id} = CacheHelpers.insert_data_structure()

      assert %{link_count: 0, link_tags: ["_none"]} = BusinessConcepts.get_concept_counts(id)

      CacheHelpers.insert_link(id, "business_concept", "data_structure", data_structure_id)

      assert %{link_count: 1, link_tags: ["_tagless"]} = BusinessConcepts.get_concept_counts(id)

      CacheHelpers.insert_link(id, "business_concept", "data_structure", data_structure_id, "foo")
      CacheHelpers.insert_link(id, "business_concept", "data_structure", data_structure_id, "bar")

      assert %{link_count: 3, link_tags: link_tags} = BusinessConcepts.get_concept_counts(id)
      assert_lists_equal(link_tags, ["foo", "bar"])
    end
  end

  defp concept_taxonomy(_) do
    import CacheHelpers, only: [insert_domain: 0, insert_domain: 1]

    [%{id: domain_id} | _] =
      domains =
      Enum.reduce(1..5, nil, fn
        _, nil -> [insert_domain()]
        _, [%{id: id} | _] = acc -> [insert_domain(parent_id: id) | acc]
      end)

    concept = insert(:business_concept_version, domain_id: domain_id)

    [concept: concept, domains: domains]
  end

  describe "add_parents/1" do
    setup :concept_taxonomy

    test "add_parents/1 gets concept taxonomy", %{concept: concept, domains: domains} do
      parents = Enum.map(domains, &Map.take(&1, [:external_id, :id, :name]))

      assert %{domain_parents: ^parents} = BusinessConcepts.add_parents(concept)
    end
  end

  @tag template: @content
  test "with invalid content: required" do
    %{user_id: user_id} = build(:claims)
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
      "data_owner" => %{"value" => "domain", "origin" => "user"},
      "link" => %{
        "value" => [
          %{
            "url_name" => "https://google.es",
            "url_value" => "https://google.es"
          }
        ],
        "origin" => "user"
      },
      "lista" => %{"value" => ["codigo1"], "origin" => "user"},
      "texto_libre" => %{"value" => RichText.to_rich_text("free text"), "origin" => "user"}
    }

    concept_attrs = %{
      type: @template_name,
      domain_id: domain.id,
      last_change_by: user_id,
      last_change_at: DateTime.utc_now()
    }

    version_attrs = %{
      business_concept: concept_attrs,
      content: content,
      name: "some name",
      last_change_by: user_id,
      last_change_at: DateTime.utc_now(),
      version: 1
    }

    creation_attrs = Map.put(version_attrs, :content_schema, content_schema)

    assert {:ok, %{business_concept_version: business_concept_version}} =
             BusinessConcepts.create_business_concept(creation_attrs)

    assert business_concept_version.content == %{
             "data_owner" => %{"value" => "domain", "origin" => "user"},
             "link" => %{
               "value" => [
                 %{
                   "url_name" => "https://google.es",
                   "url_value" => "https://google.es"
                 }
               ],
               "origin" => "user"
             },
             "lista" => %{"value" => ["codigo1"], "origin" => "user"},
             "texto_libre" => %{"value" => RichText.to_rich_text("free text"), "origin" => "user"}
           }

    assert business_concept_version.name == version_attrs.name

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

  describe "share/2" do
    test "shares a business concept to a group of domains" do
      concept = %{id: concept_id} = insert(:business_concept)
      d1 = %{id: domain_id1} = insert(:domain)
      d2 = %{id: domain_id2} = insert(:domain)

      assert {:ok,
              %{
                audit: event_id,
                updated: %{id: ^concept_id, shared_to: [%{id: ^domain_id1}, %{id: ^domain_id2}]}
              }} = BusinessConcepts.share(concept, [d1.id, d2.id])

      assert {:ok, [%{payload: payload, id: ^event_id}]} =
               Stream.read(:redix, @stream, transform: true)

      assert %{"shared_to" => [%{"id" => ^domain_id1}, %{"id" => ^domain_id2}]} =
               Jason.decode!(payload)
    end

    test "updates an existing relation between a business concept and a group of domains" do
      d1 = insert(:domain)
      d2 = %{id: domain_id2} = insert(:domain)
      d3 = %{id: domain_id3} = insert(:domain)

      concept = %{id: concept_id} = insert(:business_concept)
      insert(:shared_concept, business_concept: concept, domain: d1)
      insert(:shared_concept, business_concept: concept, domain: d2)

      assert {:ok,
              %{
                audit: event_id,
                updated: %{id: ^concept_id, shared_to: [%{id: ^domain_id2}, %{id: ^domain_id3}]}
              }} = BusinessConcepts.share(concept, [d2.id, d3.id])

      assert {:ok, [%{payload: payload, id: ^event_id}]} =
               Stream.read(:redix, @stream, transform: true)

      assert %{"shared_to" => [%{"id" => ^domain_id2}, %{"id" => ^domain_id3}]} =
               Jason.decode!(payload)
    end

    test "deletes an existing relation between a business concept and a group of domains" do
      d1 = insert(:domain)
      d2 = insert(:domain)

      concept = %{id: concept_id} = insert(:business_concept)
      insert(:shared_concept, business_concept: concept, domain: d1)
      insert(:shared_concept, business_concept: concept, domain: d2)

      assert {:ok,
              %{
                audit: event_id,
                updated: %{id: ^concept_id, shared_to: []}
              }} = BusinessConcepts.share(concept, [])

      assert {:ok, [%{payload: payload, id: ^event_id}]} =
               Stream.read(:redix, @stream, transform: true)

      assert %{"shared_to" => []} = Jason.decode!(payload)
    end
  end

  describe "generate_vector/2" do
    test "generates vector for business concept version" do
      bcv = %{business_concept: business_concept} = insert(:business_concept_version)

      Embeddings.generate_vector(
        &Mox.expect/4,
        "#{bcv.name} #{business_concept.type} #{business_concept.domain.external_id}",
        nil,
        {:ok, {"default", [54.0, 10.2, -2.0]}}
      )

      assert {"default", [54.0, 10.2, -2.0]} == BusinessConcepts.generate_vector(bcv)
    end

    test "generates vector for business concept version including content descriptions and links" do
      template = %{
        id: 0,
        name: "test_template",
        label: "label",
        scope: "test",
        content: [
          %{
            "name" => "group",
            "fields" => [
              %{
                "name" => "Field1",
                "type" => "enriched_text",
                "widget" => "enriched_text",
                "cardinality" => "?",
                "default" => %{"value" => "", "origin" => "user"}
              }
            ]
          }
        ]
      }

      on_exit(fn -> Templates.delete(template.id) end)

      Templates.create_template(template)

      content_description = "Field 1 description"

      content = %{
        "Field1" => %{"value" => RichText.to_rich_text(content_description), "origin" => "user"}
      }

      business_concept = build(:business_concept, type: template.name)

      bcv =
        %{business_concept: business_concept} =
        insert(:business_concept_version, business_concept: business_concept, content: content)

      link_name = "data structure name"
      link_type = "data structure type"
      link_description = "data structure description"

      data_structure =
        CacheHelpers.insert_data_structure(%{
          name: link_name,
          type: link_type,
          description: link_description
        })

      CacheHelpers.insert_link(
        data_structure.id,
        "data_structure",
        "business_concept",
        business_concept.id
      )

      Embeddings.generate_vector(
        &Mox.expect/4,
        "#{bcv.name} #{business_concept.type} #{business_concept.domain.external_id} #{content_description} #{link_name} #{link_type} #{link_description}",
        nil,
        {:ok, {"default", [54.0, 10.2, -2.0]}}
      )

      assert {"default", [54.0, 10.2, -2.0]} == BusinessConcepts.generate_vector(bcv)
    end

    test "generates vector for business concept version and collection" do
      bcv = %{business_concept: business_concept} = insert(:business_concept_version)
      collection_name = "collection"

      Embeddings.generate_vector(
        &Mox.expect/4,
        "#{bcv.name} #{business_concept.type} #{business_concept.domain.external_id}",
        collection_name,
        {:ok, {collection_name, [54.0, 10.2, -2.0]}}
      )

      assert {collection_name, [54.0, 10.2, -2.0]} ==
               BusinessConcepts.generate_vector(bcv, collection_name)
    end
  end

  defp business_concept_version_preload(business_concept_version, preload \\ [:domain]) do
    business_concept_version
    |> Repo.preload(:business_concept)
    |> Repo.preload(business_concept: preload)
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
    id = System.unique_integer([:positive])
    "Concept #{id}"
  end
end
