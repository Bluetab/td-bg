defmodule TdBGWeb.SwaggerDefinitions do
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
          data Schema.ref(:DataDomains)
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
              user :string, "user name"
              role :string, "role name"
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
          data Schema.ref(:DomainGroups)
        end
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

  def business_concept_definitions do
    %{
      BusinessConcept: swagger_schema do
        title "Business Concept"
        description "Business Concept"
        properties do
          id :integer, "unique identifier", required: true
          business_concept_version_id :integer, "Business Concept current version id"
          type :string, "Business Concept type"
          content :object, "Business Concept content"
          name :string, "Business Concept name"
          description :string, "Business Concept description"
          last_change_by :integer, "Business Concept last updated by"
          last_change_at :string, "Business Conceptlast updated date"
          data_domain_id :integer, "Business Concept parent data domain id"
          status :string, "Business Conceptstatus"
          version :integer, "Business Concept version"
          reject_reason [:string, :null], "Business Concept reject reason"
          mod_comments [:string, :null], "Business Concept modification comments"
        end
      end,
      BusinessConceptCreate: swagger_schema do
        properties do
          business_concept (Schema.new do
            properties do
              type :string, "Business Concept type (empty,...)", required: true
              content :object, "Business Concept content", required: true
              name :string, "Business Concept name", required: true
              description :string, "Business Conceptdescription", required: true
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
          data Schema.ref(:BusinessConcepts)
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
          name :string, "Business Concept Version name", required: true
          description :string, "Business Concept Version description"
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
              business_concept_id :integer, "usiness Concept id", required: true
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
          data Schema.ref(:BusinessConceptVersion)
        end
      end,
      BusinessConceptVersionsResponse: swagger_schema do
        properties do
          data Schema.ref(:BusinessConceptVersions)
        end
      end
    }
  end

end
