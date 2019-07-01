defmodule TdBgWeb.SwaggerDefinitions do
  @moduledoc """
  Swagger definitions used by controllers
  """
  import PhoenixSwagger

  def domain_swagger_definitions do
    %{
      DomainActions:
        swagger_schema do
          title("Domain")
          description("A Domain")

          properties do
            id(:integer, "Unique identifier", required: true)
            name(:string, "Domain name", required: true)
            type(:string, "type")
            description(:string, "description")
            parent_id([:integer, :null], "Domain id")
            _actions(Schema.ref(:Actions))
          end

          example(%{
            id: 12,
            name: "Domain name",
            type: "Domain type",
            description: "domain description",
            parent_id: 1,
            _actions: %{}
          })
        end,
      Domain:
        swagger_schema do
          title("Domain")
          description("A Domain")

          properties do
            id(:integer, "Unique identifier", required: true)
            name(:string, "Domain name", required: true)
            type([:string, :null], "type")
            description(:string, "description")
            parent_id([:integer, :null], "Domain id")
          end

          example(%{
            id: 12,
            name: "Domain name",
            type: "Domain type",
            description: "domain description",
            parent_id: 1
          })
        end,
      DomainRef:
        swagger_schema do
          title("Domain Reference")
          description("A Domain's id and name")

          properties do
            id(:integer, "Domain Identifier", required: true)
            name(:string, "Domain Name", required: true)
          end

          example(%{
            id: 12,
            name: "Domain name"
          })
        end,
      TemplateRef:
        swagger_schema do
          title("Template Reference")
          description("A Template's id and name")

          properties do
            id(:integer, "Template Id", required: true)
            name(:string, "Template Name", required: true)
          end
        end,
      DomainCreate:
        swagger_schema do
          properties do
            domain(
              Schema.new do
                properties do
                  name(:string, "domain name", required: true)
                  type(:string, "domain type")
                  description(:string, "domain description")
                  parent_id(:integer, "parent domain id")
                end
              end
            )
          end
        end,
      DomainUpdate:
        swagger_schema do
          properties do
            domain(
              Schema.new do
                properties do
                  name(:string, "domain name", required: true)
                  type(:string, "domain type")
                  description(:string, "domain description")
                end
              end
            )
          end
        end,
      Domains:
        swagger_schema do
          title("Domains")
          description("A collection of Domains")
          type(:array)
          items(Schema.ref(:DomainResponseNoData))
        end,
      DomainResponseNoData:
        swagger_schema do
          properties do
            data(Schema.ref(:DomainActions))
          end
        end,
      DomainResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:Domain))
            _actions(Schema.ref(:Actions))
          end
        end,
      DomainsResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:Domains))
            actions(Schema.ref(:Actions))
          end
        end,
      Actions:
        swagger_schema do
          title("Actions")
          description("Domain actions")

          properties do
            action(
              Schema.new do
                properties do
                  method(:string)
                  input(:object)
                  link(:string)
                end
              end
            )
          end

          example(%{
            create: %{
              method: "POST",
              href: "/api/domains",
              input: %{}
            }
          })
        end,
      BCInDomainCountResponse:
        swagger_schema do
          title("Counter")

          description(
            "Counter with the business concepts in a domain for a user having a role on these concepts"
          )

          properties do
            couter(:integer, "BC Count")
          end

          example(%{
            counter: 12
          })
        end
    }
  end

  def business_concept_version_definitions do
    %{
      BusinessConceptVersion:
        swagger_schema do
          title("Business Concept Version")
          description("Business Concept Version")

          properties do
            id(:integer, "unique identifier", required: true)
            business_concept_id(:integer, "Business Concept unique id", required: true)
            type(:string, "Business Concept type", required: true)
            content(:object, "Business Concept Version content", required: true)

            related_to(
              :array,
              "Related Business Concepts",
              items: %{type: :integer},
              required: true
            )

            name(:string, "Business Concept Version name", required: true)
            description(:object, "Business Concept Version description", required: true)
            last_change_by(:integer, "Business Concept Version last change by", required: true)
            last_change_at(:string, "Business Concept Version last change at", required: true)
            domain(Schema.ref(:DomainRef))
            parent_id([:integer, :null], "Parent Business Concept ID", required: true)
            parent(:object, "Parent Business Concept", required: false)
            children(:array, "Children Business Concepts", required: false)
            status(:string, "Business Concept Version status", required: true)
            current(:boolean, "Is this the current version?", required: true)
            version(:integer, "Business Concept Version version number", required: true)

            reject_reason(
              [:string, :null],
              "Business Concept Version rejection reason",
              required: false
            )

            mod_comments(
              [:string, :null],
              "Business Concept Version modification comments",
              required: false
            )
          end
        end,
      BusinessConceptVersionUpdate:
        swagger_schema do
          properties do
            business_concept_version(
              Schema.new do
                properties do
                  content(:object, "Business Concept Version content")
                  name(:string, "Business Concept Version name")
                  description(:object, "Business Concept Version description")
                  parent_id(:object, "Parent Business Concept ID")
                end
              end
            )
          end
        end,
      BulkUpdateRequest:
        swagger_schema do
          properties do
            bulk_update_request(
              Schema.new do
                properties do
                  update_attributes(:object, "Update attributes")
                  search_params(:object, "Search params")
                end
              end
            )
          end
        end,
      BusinessConceptVersions:
        swagger_schema do
          title("Business Concept Versions")
          description("A collection of Business Concept Versions")
          type(:array)
          items(Schema.ref(:BusinessConceptVersion))
        end,
      BusinessConceptVersionIDs:
        swagger_schema do
          title("Business Concept Version IDs updated")
          description("An array of Business Concept Version IDs")
          type(:array)
          items(%{type: :integer})
        end,
      BulkUpdateResponse:
        swagger_schema do
          properties do
            data(
              Schema.new do
                properties do
                  message(Schema.ref(:BusinessConceptVersionIDs))
                end
              end
            )
          end
        end,
      BusinessConceptVersionResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:BusinessConceptVersion))
          end
        end,
      BusinessConceptVersionsResponse:
        swagger_schema do
          properties do
            data(
              Schema.new do
                properties do
                  collection(Schema.ref(:BusinessConceptVersions))
                end
              end
            )
          end
        end,
      BusinessConceptVersionCreate:
        swagger_schema do
          properties do
            business_concept_version(
              Schema.new do
                properties do
                  type(:string, "Business Concept type (empty,...)", required: true)
                  content(:object, "Business Concept content", required: true)
                  name(:string, "Business Concept name", required: true)
                  description(:object, "Business Concept description", required: true)
                  domain_id(:integer, "Business Concept Domain ID", required: true)
                  parent_id(:integer, "Parent Business Concept ID", required: false)
                end
              end
            )
          end
        end,
      BusinessConceptVersionFilterRequest:
        swagger_schema do
          properties do
            query(:string, "Query string", required: false)
            filters(:object, "Filters", required: false)
          end

          example(%{
            query: "searchterm",
            filters: %{
              domain: ["Domain1", "Domain2"],
              status: ["draft"],
              data_owner: ["user1"]
            }
          })
        end,
      ConceptField:
        swagger_schema do
          title("Concept Field")
          description("Concept Field representation")

          properties do
            id(:integer, "Concept Field Id", required: true)
            concept(:string, "Business Concept", required: true)
            field(:object, "Data field", required: true)
          end
        end,
      ConceptFields:
        swagger_schema do
          title("Concept Fields")
          description("A collection of concept fields")
          type(:array)
          items(Schema.ref(:ConceptField))
        end,
      ConceptFieldsResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:ConceptFields))
          end
        end,
      DataStructure:
        swagger_schema do
          title("Data Structure")
          description("A Data Structure")

          properties do
            id(:integer, "Data Structure id", required: true)
            ou(:string, "Data Structure orgainzation", required: true)
            system(:string, "Data Structure system", required: true)
            group(:string, "Data Structure group", required: true)
            name(:string, "Data Structure name", required: true)
          end
        end,
      DataStructures:
        swagger_schema do
          title("Data Structures")
          description("A collection of data structures")
          type(:array)
          items(Schema.ref(:DataStructure))
        end,
      DataStructureResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:DataStructure))
          end
        end,
      DataStructuresResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:DataStructures))
          end
        end,
      DataField:
        swagger_schema do
          title("Data Field")
          description("A Data Field")

          properties do
            id(:integer, "Data Field id", required: true)
            name(:string, "Data Field name", required: true)
          end
        end,
      DataFields:
        swagger_schema do
          title("Data Fields")
          description("A collection of data fields")
          type(:array)
          items(Schema.ref(:DataField))
        end,
      DataFieldResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:DataField))
          end
        end,
      DataFieldsResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:DataFields))
          end
        end
    }
  end

  def business_concept_alias_definitions do
    %{
      BusinessConceptAlias:
        swagger_schema do
          title("Business Concept Alias")
          description("Business Concept Alias")

          properties do
            id(:integer, "unique identifier", required: true)
            business_concept_id(:integer, "Business Concept unique id", required: true)
            name(:string, "Business Concept Alias", required: true)
          end
        end,
      BusinessConceptAliasCreate:
        swagger_schema do
          properties do
            business_concept_alias(
              Schema.new do
                properties do
                  name(:string, "Business Concept Alias")
                end
              end
            )
          end
        end,
      BusinessConceptAliases:
        swagger_schema do
          title("Business Concept Aliases")
          description("A collection of Business Concept Aliases")
          type(:array)
          items(Schema.ref(:BusinessConceptAlias))
        end,
      BusinessConceptAliasResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:BusinessConceptAlias))
          end
        end,
      BusinessConceptAliasesResponse:
        swagger_schema do
          properties do
            data(
              Schema.new do
                properties do
                  collection(Schema.ref(:BusinessConceptAliases))
                end
              end
            )
          end
        end
    }
  end

  def filter_swagger_definitions do
    %{
      FilterResponse:
        swagger_schema do
          title("Filters")

          description(
            "An object whose keys are filter names and values are arrays of filterable values"
          )

          properties do
            data(:object, "Filter values", required: true)
          end

          example(%{
            data: %{
              domain: ["Domain 1", "Domain 2"],
              language: ["Spanish", "English", "French"]
            }
          })
        end
    }
  end

  def comment_swagger_definitions do
    %{
      Comment:
        swagger_schema do
          title("Comment")
          description("A Data Structure/Field Comment")

          properties do
            id(:integer, "Comment unique identifier", required: true)
            resource_id(:integer, "Resource identifier", required: true)
            resource_type(:string, "Resource type", required: true)
            user_id(:integer, "User identifier", required: true)
            content(:string, "Comment content", required: true)
          end

          example(%{
            resource_id: 123,
            resource_type: "Field",
            user_id: 1,
            content: "This is a comment"
          })
        end,
      CommentCreate:
        swagger_schema do
          properties do
            comment(
              Schema.new do
                properties do
                  resource_id(:integer, "Resource identifier", required: true)
                  resource_type(:string, "Resource type", required: true)
                  content(:string, "Comment content", required: true)
                end
              end
            )
          end
        end,
      CommentUpdate:
        swagger_schema do
          properties do
            comment(
              Schema.new do
                properties do
                  content(:string, "Comment content")
                end
              end
            )
          end
        end,
      Comments:
        swagger_schema do
          title("Comments")
          description("A collection of Comments")
          type(:array)
          items(Schema.ref(:Comment))
        end,
      CommentResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:Comment))
          end
        end,
      CommentsResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:Comments))
          end
        end
    }
  end
end
