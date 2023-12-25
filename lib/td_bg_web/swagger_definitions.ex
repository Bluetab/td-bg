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
            external_id([:string, :null], "Domain external id")
            type(:string, "type")
            description(:string, "description")
            parent_id([:integer, :null], "Domain id")
            _actions(Schema.ref(:Actions))
          end

          example(%{
            id: 12,
            name: "Domain name",
            type: "Domain type",
            external_id: "external id",
            description: "domain description",
            parent_id: 1,
            _actions: %{}
          })
        end,
      DomainIds:
        swagger_schema do
          title("Domain Ids")
          description("An array of Domain Ids")
          type(:array)
          items(%{type: :integer})
        end,
      Domain:
        swagger_schema do
          title("Domain")
          description("A Domain")

          properties do
            id(:integer, "Unique identifier", required: true)
            name(:string, "Domain name", required: true)
            external_id([:string, :null], "Domain external id")
            type([:string, :null], "type")
            description(:string, "description")
            parent_id([:integer, :null], "Domain id")
            domain_group([:object, :null], "Domain group")
            parentable_ids(Schema.ref(:DomainIds))
          end

          example(%{
            id: 12,
            name: "Domain name",
            type: "Domain type",
            external_id: "external id",
            description: "domain description",
            parent_id: 1
          })
        end,
      DomainRefs:
        swagger_schema do
          title("Domains")
          description("A collection of Domains")
          nullable(true)
          type(:array)
          items(Schema.ref(:DomainRef))
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
                  external_id([:string, :null], "Domain external id")
                  description(:string, "domain description")
                  parent_id(:integer, "parent domain id")
                  domain_group(:string, "domain group")
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
                  external_id([:string, :null], "Domain external id")
                  type(:string, "domain type")
                  description(:string, "domain description")
                  domain_group(:string, "domain group")
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
            name(:string, "Business Concept Version name", required: true)
            last_change_by(:integer, "Business Concept Version last change by", required: true)
            last_change_at(:string, "Business Concept Version last change at", required: true)
            domain(Schema.ref(:DomainRef))
            status(:string, "Business Concept Version status", required: true)
            current(:boolean, "Is this the current version?", required: true)
            version(:integer, "Business Concept Version version number", required: true)
            domain_parents(Schema.ref(:DomainRefs))

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
                end
              end
            )
          end
        end,
      BusinessConceptVersionDomainUpdate:
        swagger_schema do
          properties do
            domain_id(:integer, "Business Concept Domain ID", required: true)
          end
        end,
      BusinessConceptVersionConfidentialUpdate:
        swagger_schema do
          properties do
            confidential(:boolean, "true for confidential or false for public")
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
                  domain_id(:integer, "Business Concept Domain ID", required: true)
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
      BusinessConceptResponse:
        swagger_schema do
          properties do
            data(
              Schema.new do
                properties do
                  id(:integer, "Business concept id", required: true)
                  _embedded(Schema.ref(:EmbeddedSharedTo))
                end
              end
            )
          end
        end,
      EmbeddedSharedTo:
        swagger_schema do
          properties do
            shared_to(Schema.ref(:Domains))
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
            content(:string, "Comment content", required: true)
            user(:object, "Comment user", required: true)
          end

          example(%{
            resource_id: 123,
            resource_type: "Field",
            content: "This is a comment",
            user: %{
              user_id: 123,
              user_name: "user123",
              full_name: "Joe Bloggs"
            }
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

  def user_search_filters_definitions do
    %{
      UserSearchFilter:
        swagger_schema do
          title("User search filter")
          description("A User search filter")

          properties do
            id(:integer, "User search filter unique identifier", required: true)
            name(:string, "Name", required: true)
            user_id(:integer, "Current user id", required: true)
            filters(:object, "Search filters")
          end

          example(%{
            id: 5,
            name: "Tipo basic",
            user_id: 3,
            filters: %{
              "pais" => ["Australia", "", "Argelia"],
              "link_tags" => ["_tagless"]
            }
          })
        end,
      UserSearchFilters:
        swagger_schema do
          title("UserSearchFilters")
          description("A collection of user search filter")
          type(:array)
          items(Schema.ref(:UserSearchFilter))
        end,
      CreateUserSearchFilter:
        swagger_schema do
          properties do
            user_search_filter(
              Schema.new do
                properties do
                  name(:string, "Search name", required: true)
                  filters(:object, "Search filters")
                end
              end
            )
          end
        end,
      UserSearchFilterResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:UserSearchFilter))
          end
        end,
      UserSearchFiltersResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:UserSearchFilters))
          end
        end
    }
  end
end
