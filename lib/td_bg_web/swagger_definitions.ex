defmodule TdBgWeb.SwaggerDefinitions do
  @moduledoc """
   Swagger definitions used by controllers
  """
  import PhoenixSwagger

  def data_domain_swagger_definitions do
    %{
      DataDomain: swagger_schema do
        title "Data Domain"
        description "A Data Domain child of a Domain Group"
        properties do
          id :integer, "Unique identifier", required: true
          name :string, "data domain name", required: true
          descritpion :string, "descritpion"
          domain_group_id [:integer, :null], "Domain Group Id", required: true
        end
        example %{
        id: 123,
        name: "Data domain name",
        domain_group_id: 742
        }
      end,
      DataDomainCreate: swagger_schema do
        properties do
          data_domain (Schema.new do
            properties do
              name :string, "data domain name", required: true
              description :string, "data domain description"
            end
          end)
        end
      end,
      DataDomainUpdate: swagger_schema do
        properties do
          data_domain (Schema.new do
            properties do
             name :string, "data domain name"
             description :string, "data domain description"
            end
          end)
        end
      end,
      DataDomains: swagger_schema do
        title "Data Domains"
        description "A collection of Data Domains"
        type :array
        items Schema.ref(:DataDomain)
      end,
      DataDomainResponse: swagger_schema do
        properties do
          data Schema.ref(:DataDomain)
        end
      end,
      DataDomainsResponse: swagger_schema do
        properties do
          data (Schema.new do
            properties do
              collection Schema.ref(:DataDomains)
            end
          end)
        end
      end,
      UsersRolesRequest: swagger_schema do
        properties do
          data :object
        end
      end,
      UsersRolesResponse: swagger_schema do
        properties do
          data (Schema.new do
            properties do
              user_id :integer, "user id"
              user_name :string, "user name"
              role_id :integer, "role id"
              role_name :string, "role name"
              acl_entry_id :integer, "acl entry id"
            end
          end)
        end
      end
    }
  end

  def domain_group_swagger_definitions do
    %{
      DomainGroup: swagger_schema do
        title "Domain Group"
        description "A Domain Group"
        properties do
          id :integer, "Unique identifier", required: true
          name :string, "data domain name", required: true
          descritpion :string, "descritpion"
          parent_id [:integer, :null], "Domain Group id", required: true
        end
        example %{
          id: 12,
          name: "Domain group name",
          description: "dg description",
          parent_id: 1
        }
      end,
      DomainGroupCreate: swagger_schema do
        properties do
          domain_group (Schema.new do
            properties do
              name :string, "domain group name", required: true
              description :string, "domain group description"
              parent_id :integer, "parent domain group id"
             end
          end)
        end
      end,
      DomainGroupUpdate: swagger_schema do
        properties do
          domain_group (Schema.new do
            properties do
              name :string, "domain group name", required: true
              description :string, "domain group description"
            end
          end)
        end
      end,
      DomainGroups: swagger_schema do
        title "Domain Groups"
        description "A collection of Domain Groups"
        type :array
        items Schema.ref(:DomainGroup)
      end,
      DomainGroupResponse: swagger_schema do
        properties do
          data Schema.ref(:DomainGroup)
        end
      end,
      DomainGroupsResponse: swagger_schema do
        properties do
          data (Schema.new do
            properties do
              collection Schema.ref(:DomainGroups)
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
      end
    }
  end

  def taxonomy_swagger_definitions do
    %{
      TreeItem: swagger_schema do
        properties do
          id :integer
          type :string
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
              type: "DG",
              name: "dg 1",
              id: 1,
              description: "dg root 1",
              children:
                [
                %{
                  type: "DD",
                  name: "dd1",
                  id: 1,
                  description: "dd1 child of dg1",
                  children: []
                }
              ]
            }
          ]
        }
      end,
      DGDDItem: swagger_schema do
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
              domain_groups Schema.ref(:DGDDItem)
              data_domains Schema.ref(:DGDDItem)
            end
          end)
        end
        example %{
          data: [
            %{
              data_domains: %{"93": %{inherited: false, role: "admin", role_id: 1, acl_entry_id: 1}, "94": %{inherited: true, role: "publish", role_id: 2, acl_entry_id: nil}},
              domain_groups: %{"69": %{inherited: false, role: "publish", role_id: 2, acl_entry_id: 2}, "70": %{inherited: true, role: "publish", role_id: 2, acl_entry_id: nil}}
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
          resource_type :string, "type of resource: data_domain / domain_group", required: true
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
              resource_type :string, "type of resource: data_domain / domain_group", required: true
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
                         resource_type :string, "type of resource: data_domain / domain_group", required: true
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

  def business_concept_type_definitions do
    %{
     BusinessConceptType: swagger_schema do
       properties do
        type_name :string
       end
     end,
     BusinessConceptTypes: swagger_schema do
      title "Business Concept Types"
      description "A collection of Business Concept Types"
      type :array
      items Schema.ref(:BusinessConceptType)
      end,
      BusinessConceptTypesResponse: swagger_schema do
        properties do
          data Schema.ref(:BusinessConceptTypes)
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
          data_domain_id :integer, "Business Concept parent data domain id", required: true
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
              data_domain_id :integer, "Business Concept Data Domain ID", required: true
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
          data_domain_id :integer, "Belongs to Data Domain", required: true
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

end
