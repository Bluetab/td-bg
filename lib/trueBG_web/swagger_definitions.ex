defmodule TrueBGWeb.SwaggerDefinitions do
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
          domain_group_id :integer, "Domain Group Id", required: true
          #domain_group Schema.ref(:DomainGroup)
        end
        example %{
        id: 123,
        name: "Data domain name",
        domain_group_id: 742
        }
      end,
      DataDomainCreate: swagger_schema do
        properties do
          name :string, "data domain name", required: true
          description :string, "data domain description"
        end
      end,
      DataDomainUpdate: swagger_schema do
        properties do
          name :string, "data domain name"
          description :string, "data domain description"
        end
      end,
      DataDomains: swagger_schema do
        title "Data Domains"
        description "A collection of Data Domains"
        type :array
        items Schema.ref(:DataDomain)
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
          parent_id :integer, "Domain Group id"
        end
        example %{
          id: 12,
          name: "Domain group name",
          parent_id: nil
        }
      end,
      DomainGroupCreate: swagger_schema do
        properties do
          name :string, "domain group name", required: true
          description :string, "domain group description"
          parent_id :integer, "parent domain group id"
        end
      end,
      DomainGroupUpdate: swagger_schema do
        properties do
          name :string, "domain group name", required: true
          description :string, "domain group description"
        end
      end,
      DomainGroups: swagger_schema do
        title "Domain Groups"
        description "A collection of Domain Groups"
        type :array
        items Schema.ref(:DomainGroup)
      end
    }
  end

end
