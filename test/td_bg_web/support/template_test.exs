defmodule TdBg.TemplateSupportTest do
  use TdBg.DataCase

  alias TdBg.BusinessConcepts
  alias TdBg.Permissions.MockPermissionResolver
  alias TdBgWeb.ApiServices.MockTdAuthService

  setup_all do
    start_supervised(MockTdAuthService)
    start_supervised(MockPermissionResolver)
    :ok
  end

  defp create_user do
    jti = to_string(:rand.uniform(10_000))
    user = build(:user, jti: jti)
    sub = %{"id" => user.id} |> Poison.encode!()
    MockPermissionResolver.register_token(
      %{"sub" => sub, "jti" => jti}
    )

    user
  end

  describe "template support" do
    alias TdBgWeb.TemplateSupport

    test "get_template/1" do
      content = []
      template = insert(:template, content: content)
      concept  = insert(:business_concept, type: template.name)
      version  = insert(:business_concept_version, business_concept: concept)

      stored_version  = BusinessConcepts.get_business_concept_version!(version.id)
      stored_template = TemplateSupport.get_template(stored_version)
      assert template.name == stored_template.name
    end

    test "get_preprocessed_template/2 user without permission to view confidential content" do
      user     = create_user()
      content  = [%{name: "_confidential"}]
      template = insert(:template, content: content)
      domain   = insert(:domain)
      concept  = insert(:business_concept, type: template.name, domain: domain)
      version  = insert(:business_concept_version, business_concept: concept)

      role = MockTdAuthService.find_or_create_role("myrole")
      MockPermissionResolver.create_acl_entry(%{
        principal_id: user.id,
        principal_type: "user",
        resource_id: domain.id,
        resource_type: "domain",
        role_id: role.id,
        role_name: role.name
      })

      stored_version  = BusinessConcepts.get_business_concept_version!(version.id)
      stored_template = TemplateSupport.get_preprocessed_template(stored_version, user)
      expected_content = [%{ "default" => "No",
                             "disabled" => true,
                             "name" => "_confidential",
                             "required" => false,
                             "type" => "list",
                             "values" => ["Si", "No"],
                             "widget" => "checkbox"}]
      assert JSONDiff.diff(stored_template.content, expected_content) == []
    end

    test "get_preprocessed_template/2 user with permission to view confidential content" do
      user = create_user()
      content  = [%{name: "_confidential"}]
      template = insert(:template, content: content)
      domain   = insert(:domain)
      concept  = insert(:business_concept, type: template.name, domain: domain)
      version  = insert(:business_concept_version, business_concept: concept)

      role = MockTdAuthService.find_or_create_role("admin")
      MockPermissionResolver.create_acl_entry(%{
        principal_id: user.id,
        principal_type: "user",
        resource_id: domain.id,
        resource_type: "domain",
        role_id: role.id,
        role_name: role.name
      })

      stored_version  = BusinessConcepts.get_business_concept_version!(version.id)
      stored_template = TemplateSupport.get_preprocessed_template(stored_version, user)
      expected_content = [%{ "default" => "No",
                             "disabled" => false,
                             "name" => "_confidential",
                             "required" => false,
                             "type" => "list",
                             "values" => ["Si", "No"],
                             "widget" => "checkbox"}]
      assert JSONDiff.diff(stored_template.content, expected_content) == []
    end
  end

end
