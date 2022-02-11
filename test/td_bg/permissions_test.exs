defmodule TdBg.PermissionsTest do
  use TdBgWeb.ConnCase

  alias TdBg.Permissions

  describe "Permissions.get_search_permissions/1" do
    @tag authentication: [role: "admin"]
    test "returns a map with values :all for admin role", %{claims: claims} do
      assert Permissions.get_search_permissions(claims) == %{
               "manage_business_concept_links" => :all,
               "manage_confidential_business_concepts" => :all,
               "view_approval_pending_business_concepts" => :all,
               "view_deprecated_business_concepts" => :all,
               "view_draft_business_concepts" => :all,
               "view_published_business_concepts" => :all,
               "view_rejected_business_concepts" => :all,
               "view_versioned_business_concepts" => :all
             }
    end

    @tag authentication: [user_name: "not_an_admin"]
    test "returns a map with :none values for regular users", %{claims: claims} do
      assert Permissions.get_search_permissions(claims) == %{
               "manage_business_concept_links" => :none,
               "manage_confidential_business_concepts" => :none,
               "view_approval_pending_business_concepts" => :none,
               "view_deprecated_business_concepts" => :none,
               "view_draft_business_concepts" => :none,
               "view_published_business_concepts" => :none,
               "view_rejected_business_concepts" => :none,
               "view_versioned_business_concepts" => :none
             }
    end

    @tag authentication: [user_name: "not_an_admin"]
    test "includes :all values for default permissions", %{claims: claims} do
      CacheHelpers.put_default_permissions(["view_published_business_concepts", "foo"])

      assert Permissions.get_search_permissions(claims) == %{
               "manage_business_concept_links" => :none,
               "manage_confidential_business_concepts" => :none,
               "view_approval_pending_business_concepts" => :none,
               "view_deprecated_business_concepts" => :none,
               "view_draft_business_concepts" => :none,
               "view_published_business_concepts" => :all,
               "view_rejected_business_concepts" => :none,
               "view_versioned_business_concepts" => :none
             }
    end

    @tag authentication: [user_name: "not_an_admin"]
    test "includes domain_id values for session permissions, excepting defaults", %{
      claims: claims
    } do
      CacheHelpers.put_default_permissions(["view_published_business_concepts", "foo"])
      %{id: id1} = CacheHelpers.insert_domain()
      %{id: id2} = CacheHelpers.insert_domain(parent_id: id1)
      %{id: id3} = CacheHelpers.insert_domain()

      put_session_permissions(claims, %{
        "manage_confidential_business_concepts" => [id1],
        "view_rejected_business_concepts" => [id2],
        "view_published_business_concepts" => [id3],
        "view_deprecated_business_concepts" => [id3]
      })

      assert Permissions.get_search_permissions(claims) == %{
               "manage_business_concept_links" => :none,
               "manage_confidential_business_concepts" => [id2, id1],
               "view_approval_pending_business_concepts" => :none,
               "view_deprecated_business_concepts" => [id3],
               "view_draft_business_concepts" => :none,
               "view_published_business_concepts" => :all,
               "view_rejected_business_concepts" => [id2],
               "view_versioned_business_concepts" => :none
             }
    end
  end
end
