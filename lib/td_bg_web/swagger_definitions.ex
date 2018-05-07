defmodule TdBgWeb.SwaggerDefinitions do
  @moduledoc """
   Swagger definitions used by controllers
  """
  import PhoenixSwagger

  def domain_swagger_definitions do
    %{
      Domain: swagger_schema do
        title "Domain"
        description "A Domain"
        properties do
          id :integer, "Unique identifier", required: true
          name :string, "Domain name", required: true
          description :string, "type"
          description :string, "descritpion"
          parent_id [:integer, :null], "Domain id"
        end
        example %{
          id: 12,
          name: "Domain name",
          type: "Domain type",
          description: "domain description",
          parent_id: 1
        }
      end,
      DomainCreate: swagger_schema do
        properties do
          domain (Schema.new do
            properties do
              name :string, "domain name", required: true
              type :string, "domain type"
              description :string, "domain description"
              parent_id :integer, "parent domain id"
             end
          end)
        end
      end,
      DomainUpdate: swagger_schema do
        properties do
          domain (Schema.new do
            properties do
              name :string, "domain name", required: true
              type :string, "domain type"
              description :string, "domain description"
            end
          end)
        end
      end,
      Domains: swagger_schema do
        title "Domains"
        description "A collection of Domains"
        type :array
        items Schema.ref(:Domain)
      end,
      DomainResponse: swagger_schema do
        properties do
          data Schema.ref(:Domain)
        end
      end,
      DomainsResponse: swagger_schema do
        properties do
          data (Schema.new do
            properties do
              collection Schema.ref(:Domains)
            end
          end)
        end
      end,
      UserResponse: swagger_schema do
        properties do
          data (Schema.new do
            properties do
              id :integer, "user id"
              user_name :string, "username"
              is_admin :boolean, "is admin"
            end
          end)
        end
      end,
      UsersResponse: swagger_schema do
        type :array
        items Schema.ref(:UserResponse)
      end,
      UsersRolesRequest: swagger_schema do
        properties do
          data :object
        end
      end,
      DomainAclEntriesResponse: swagger_schema do
        properties do
          data (Schema.new do
            properties do
              principal (Schema.new do
                properties do
                  id :integer, "principal_id"
                  name :string, "group1"
                end
              end)
              principal_type :string, "principal_type"
              role_id :integer, "role id"
              role_name :string, "role name"
              acl_entry_id :integer, "acl entry id"
            end
          end)
        end
      end
    }
  end

  def taxonomy_swagger_definitions do
    %{
      TreeItem: swagger_schema do
        properties do
          id :integer
          name :string
          description :string
          children (Schema.new do
                      type :array
                      items Schema.ref(:TreeItem)
                    end)
        end
      end,
      TaxonomyTreeResponse: swagger_schema do
        properties do
          data (Schema.new do
              type :array
              items Schema.ref(:TreeItem)
          end)
        end
        example %{
          data: [
            %{
              name: "domain 1",
              id: 1,
              description: "domain root 1",
              children:
                [
                %{
                  name: "domain 2",
                  id: 1,
                  description: "domain 2 child of domain 1",
                  children: []
                }
              ]
            }
          ]
        }
      end,
      DomainItem: swagger_schema do
        properties do
          id (Schema.new do
            properties do
              role :string
              role_id :integer
              acl_entry_id :integer
              inherited :boolean
            end
          end)
        end
      end,
      TaxonomyRolesResponse: swagger_schema do
        properties do
          data (Schema.new do
            properties do
              domains Schema.ref(:DomainItem)
            end
          end)
        end
        example %{
          data: [
            %{
              domains: %{"69": %{inherited: false, role: "publish", role_id: 2, acl_entry_id: 2}, "70": %{inherited: true, role: "publish", role_id: 2, acl_entry_id: nil}}
            }
          ]
        }
      end
    }
  end

  def acl_entry_swagger_definitions do
    %{
      AclEntry: swagger_schema do
        title "Acl entry"
        description "An Acl entry"
        properties do
          id :integer, "unique identifier", required: true
          principal_id :integer, "id of principal", required: true
          principal_type :string, "type of principal: user", required: true
          resource_id :integer, "id of resource", required: true
          resource_type :string, "type of resource: domain", required: true
          role_id :integer, "id of role", required: true
        end
      end,
      AclEntryCreateUpdate: swagger_schema do
        properties do
          acl_entry (Schema.new do
            properties do
              principal_id :integer, "id of principal", required: true
              principal_type :string, "type of principal: user", required: true
              resource_id :integer, "id of resource", required: true
              resource_type :string, "type of resource: domain", required: true
              role_id :integer, "id of role", required: true
            end
          end)
        end
      end,
      AclEntryCreateOrUpdate: swagger_schema do
        properties do
          acl_entry (Schema.new do
                       properties do
                         principal_id :integer, "id of principal", required: true
                         principal_type :string, "type of principal: user", required: true
                         resource_id :integer, "id of resource", required: true
                         resource_type :string, "type of resource: domain", required: true
                         role_name :string, "role name", required: true
                       end
                     end)
        end
      end,
      AclEntries: swagger_schema do
        title "Acl entries"
        description "A collection of Acl Entry"
        type :array
        items Schema.ref(:AclEntry)
      end,
      AclEntryResponse: swagger_schema do
        properties do
          data Schema.ref(:AclEntry)
        end
      end,
      AclEntriesResponse: swagger_schema do
        properties do
          data Schema.ref(:AclEntries)
        end
      end
    }
  end

  def permission_swagger_definitions do
    %{
      Permission: swagger_schema do
        title "Permission"
        description "Permission"
        properties do
          id :integer, "unique identifier", required: true
          name :string, "permission name", required: true
        end
      end,
      PermissionItem: swagger_schema do
        properties do
          id :integer, "unique identifier", required: true
          name :string, "permission name"
        end
      end,
      PermissionItems: swagger_schema do
        type :array
        items Schema.ref(:PermissionItem)
      end,
      AddPermissionsToRole: swagger_schema do
        properties do
          permissions Schema.ref(:PermissionItems)
        end
      end,
      Permissions: swagger_schema do
        title "Roles"
        description "A collection of Permissions"
        type :array
        items Schema.ref(:Role)
      end,
      PermissionResponse: swagger_schema do
        properties do
          data Schema.ref(:Permission)
        end
      end,
      PermissionsResponse: swagger_schema do
        properties do
          data Schema.ref(:Permissions)
        end
      end
    }
  end

  def role_swagger_definitions do
    %{
      Role: swagger_schema do
        title "Role"
        description "Role"
        properties do
          id :integer, "unique identifier", required: true
          name :string, "role name", required: true
        end
      end,
      Roles: swagger_schema do
        title "Roles"
        description "A collection of Roles"
        type :array
        items Schema.ref(:Role)
      end,
      RoleCreateUpdate: swagger_schema do
        properties do
          role (Schema.new do
            properties do
              name :string, "role name", required: true
            end
          end)
        end
      end,
      RoleResponse: swagger_schema do
        properties do
          data Schema.ref(:Role)
        end
      end,
      RolesResponse: swagger_schema do
        properties do
          data Schema.ref(:Roles)
        end
      end
    }
  end

  def business_concept_definitions do
    %{
      BusinessConcept: swagger_schema do
        title "Business Concept"
        description "Business Concept"
        properties do
          id :integer, "unique identifier", required: true
          business_concept_version_id :integer, "Business Concept current version id", required: true
          type :string, "Business Concept type", required: true
          content :object, "Business Concept content", required: true
          related_to :array, "Related Business Concepts", items: %{type: :integer}, required: true
          name :string, "Business Concept name", required: true
          description :string, "Business Concept description", required: true
          last_change_by :integer, "Business Concept last updated by", required: true
          last_change_at :string, "Business Conceptlast updated date", required: true
          domain_id :integer, "Business Concept parent domain id", required: true
          status :string, "Business Conceptstatus", required: true
          version :integer, "Business Concept version", required: true
          reject_reason [:string, :null], "Business Concept reject reason", required: false
          mod_comments [:string, :null], "Business Concept modification comments", required: false
        end
      end,
      BusinessConceptCreate: swagger_schema do
        properties do
          business_concept (Schema.new do
            properties do
              type :string, "Business Concept type (empty,...)", required: true
              content :object, "Business Concept content", required: true
              name :string, "Business Concept name", required: true
              description :string, "Business Concept description", required: true
              domain_id :integer, "Business Concept Domain ID", required: true
            end
          end)
        end
      end,
      BusinessConceptUpdate: swagger_schema do
        properties do
          business_concept (Schema.new do
            properties do
              content :object, "Business Concept content"
              name :string, "Business Concept name"
              description :string, "Business Concept description"
            end
          end)
        end
      end,
      BusinessConceptUpdateStatus: swagger_schema do
        properties do
          business_concept (Schema.new do
            properties do
              status :string, "Business Concept status (rejected, published, deprecated...)", required: true
              reject_reason [:string, :null], "Business Concept reject reason"
            end
          end)
        end
      end,
      BusinessConcepts: swagger_schema do
        title "Business Concepts"
        description "A collection of Business Concepts"
        type :array
        items Schema.ref(:BusinessConcept)
      end,
      BusinessConceptResponse: swagger_schema do
        properties do
          data Schema.ref(:BusinessConcept)
        end
      end,
      BusinessConceptsResponse: swagger_schema do
        properties do
          data (Schema.new do
            properties do
              collection Schema.ref(:BusinessConcepts)
            end
          end)
        end
      end
    }
  end

  def business_concept_version_definitions do
    %{
      BusinessConceptVersion: swagger_schema do
        title "Business Concept Version"
        description "Business Concept Version"
        properties do
          id :integer, "unique identifier", required: true
          business_concept_id :integer, "Business Concept unique id", required: true
          type :string, "Business Concept type", required: true
          content :object, "Business Concept Version content", required: true
          related_to :array, "Related Business Concepts", items: %{type: :integer}, required: true
          name :string, "Business Concept Version name", required: true
          description :string, "Business Concept Version description", required: true
          last_change_by :integer, "Business Concept Version last change by", required: true
          last_change_at :string, "Business Concept Verion last change at", required: true
          domain_id :integer, "Belongs to Domain", required: true
          status :string, "Business Concept Version status", required: true
          version :integer, "Business Concept Version version number", required: true
          reject_reason [:string, :null], "Business Concept Version rejection reason", required: false
          mod_comments [:string, :null], "Business Concept Version modification comments", required: false
        end
      end,
      BusinessConceptVersionCreate: swagger_schema do
        properties do
          business_concept_version (Schema.new do
            properties do
              content :object, "Business Concept Vesion object"
              name :string, "Business Concept Vesion name"
              description :string, "Business Concept Version description"
              mod_comments :string, "Business Concept Version modification comments"
            end
          end)
        end
      end,
      BusinessConceptVersions: swagger_schema do
        title "Business Concept Versions"
        description "A collection of Business Concept Versions"
        type :array
        items Schema.ref(:BusinessConceptVersion)
      end,
      BusinessConceptVersionResponse: swagger_schema do
        properties do
          data (Schema.new do
            properties do
              collection Schema.ref(:BusinessConceptVersion)
            end
          end)
        end
      end,
      BusinessConceptVersionsResponse: swagger_schema do
        properties do
          data (Schema.new do
            properties do
              collection Schema.ref(:BusinessConceptVersions)
            end
          end)
        end
      end
    }
  end

  def business_concept_alias_definitions do
    %{
      BusinessConceptAlias: swagger_schema do
        title "Business Concept Alias"
        description "Business Concept Alias"
        properties do
          id :integer, "unique identifier", required: true
          business_concept_id :integer, "Business Concept unique id", required: true
          name :string, "Business Concept Alias", required: true
        end
      end,
      BusinessConceptAliasCreate: swagger_schema do
        properties do
          business_concept_alias (Schema.new do
            properties do
              name :string, "Business Concept Alias"
            end
          end)
        end
      end,
      BusinessConceptAliases: swagger_schema do
        title "Business Concept Aliases"
        description "A collection of Business Concept Aliases"
        type :array
        items Schema.ref(:BusinessConceptAlias)
      end,
      BusinessConceptAliasResponse: swagger_schema do
        properties do
          data Schema.ref(:BusinessConceptAlias)
        end
      end,
      BusinessConceptAliasesResponse: swagger_schema do
        properties do
          data (Schema.new do
            properties do
              collection Schema.ref(:BusinessConceptAliases)
            end
          end)
        end
      end
    }
  end
  def template_swagger_definitions do
    %{
      Template: swagger_schema do
        title "Template"
        description "A Template"
        properties do
          name :string, "Name", required: true
          content :array, "Content", required: true
        end
        example %{
          name: "Template1",
          content: [
            %{name: "name1", max_size: 100, type: "type1", required: true},
            %{related_area: "related_area1", max_size: 100, type: "type2", required: false}
          ]
        }
      end,
      TemplateCreateUpdate: swagger_schema do
        properties do
          template (Schema.new do
            properties do
              name :string, "Name", required: true
              content :array, "Content", required: true
            end
          end)
        end
      end,
      Templates: swagger_schema do
        title "Templates"
        description "A collection of Templates"
        type :array
        items Schema.ref(:Template)
      end,
      TemplateResponse: swagger_schema do
        properties do
          data Schema.ref(:Template)
        end
      end,
      TemplatesResponse: swagger_schema do
        properties do
          data Schema.ref(:Templates)
        end
      end,
      TemplateItem: swagger_schema do
        properties do
          name :string, "Name", required: true
        end
      end,
      TemplateItems: swagger_schema do
        type :array
        items Schema.ref(:TemplateItem)
      end,
      AddTemplatesToDomain: swagger_schema do
        properties do
          templates Schema.ref(:TemplateItems)
        end
      end
    }
  end

end
