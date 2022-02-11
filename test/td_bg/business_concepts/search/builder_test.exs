defmodule TdBg.BusinessConcepts.Search.QueryBuilderTest do
  use ExUnit.Case

  alias TdBg.BusinessConcepts.Search.QueryBuilder

  describe "status_filter/1" do
    test "returns a match_none query if no permissions exist" do
      assert %{match_none: %{}} = QueryBuilder.status_filter(%{})
      assert %{match_none: %{}} = QueryBuilder.status_filter(%{"foo" => "bar"})
    end

    test "returns a match_all if all permissions have scope :all" do
      permissions = all_permissions()
      assert QueryBuilder.status_filter(permissions) == %{match_all: %{}}
    end

    test "returns a terms query to filter a single permitted status" do
      permissions = %{"view_draft_business_concepts" => :all}

      assert QueryBuilder.status_filter(permissions) ==
               %{term: %{"status" => "draft"}}
    end

    test "returns a terms query to filter permitted statuses" do
      permissions = %{
        "view_draft_business_concepts" => :all,
        "view_published_business_concepts" => :all
      }

      assert QueryBuilder.status_filter(permissions) ==
               %{terms: %{"status" => ["draft", "published"]}}
    end

    test "returns a boolean query to filter by status and domain_ids" do
      permissions = %{
        "view_draft_business_concepts" => [1],
        "view_published_business_concepts" => [1]
      }

      assert QueryBuilder.status_filter(permissions) == %{
               bool: %{
                 filter: [
                   %{terms: %{"status" => ["draft", "published"]}},
                   %{term: %{"domain_id" => 1}}
                 ]
               }
             }
    end

    test "returns a boolean query with a should clause for each group of scope and status" do
      permissions = %{
        "view_approval_pending_business_concepts" => [3],
        "view_draft_business_concepts" => [1, 2, 3],
        "view_published_business_concepts" => :all,
        "view_rejected_business_concepts" => [3]
      }

      assert QueryBuilder.status_filter(permissions) == %{
               bool: %{
                 should: [
                   %{
                     bool: %{
                       filter: [
                         %{terms: %{"status" => ["pending_approval", "rejected"]}},
                         %{term: %{"domain_id" => 3}}
                       ]
                     }
                   },
                   %{
                     bool: %{
                       filter: [
                         %{term: %{"status" => "draft"}},
                         %{terms: %{"domain_id" => [1, 2, 3]}}
                       ]
                     }
                   },
                   %{term: %{"status" => "published"}}
                 ]
               }
             }
    end
  end

  describe "confidential_filter/1" do
    test "returns a bool query with a must_not clause on the confidential.raw field" do
      assert QueryBuilder.confidential_filter(%{}) ==
               %{
                 bool: %{
                   must_not: [%{term: %{"confidential.raw" => true}}]
                 }
               }
    end

    test "returns nil if the permission scope is all" do
      assert QueryBuilder.confidential_filter(%{"manage_confidential_business_concepts" => :all}) ==
               nil
    end

    test "returns a bool query with two should clauses if the scope is a list of domain ids" do
      permissions = %{"manage_confidential_business_concepts" => [1, 2]}

      assert QueryBuilder.confidential_filter(permissions) == %{
               bool: %{
                 should: [
                   %{terms: %{"domain_id" => [1, 2]}},
                   %{bool: %{must_not: [%{term: %{"confidential.raw" => true}}]}}
                 ]
               }
             }
    end
  end

  describe "links_filter/1" do
    test "returns nil if the permission scope is :all" do
      permissions = %{"manage_business_concept_links" => :all}
      assert QueryBuilder.links_filter(permissions) == nil
    end

    test "returns a terms query if the scope is a list of domain ids" do
      permissions = %{"manage_business_concept_links" => [1, 2]}

      assert QueryBuilder.links_filter(permissions) ==
               %{terms: %{"domain_id" => [1, 2]}}
    end

    test "returns a match_none query otherwise" do
      assert QueryBuilder.links_filter(%{}) == %{match_none: %{}}
    end
  end

  describe "build_filters/2" do
    test "returns a match_none query for status and bool must_not for confidential" do
      assert QueryBuilder.build_filters(%{}) == [
               %{match_none: %{}},
               %{bool: %{must_not: [%{term: %{"confidential.raw" => true}}]}}
             ]
    end

    test "returns a match_all query if all permissions have scope :all" do
      permissions = all_permissions()
      assert QueryBuilder.build_filters(permissions) == [%{match_all: %{}}]
    end

    test "returns a filter by domain id, status and linkable" do
      permissions = %{
        "view_published_business_concepts" => :all,
        "view_draft_business_concepts" => [1, 2],
        "manage_confidential_business_concepts" => [2],
        "manage_business_concept_links" => [1]
      }

      assert QueryBuilder.build_filters(permissions, linkable: true) == [
               %{
                 bool: %{
                   should: [
                     %{
                       bool: %{
                         filter: [
                           %{term: %{"status" => "draft"}},
                           %{terms: %{"domain_id" => [1, 2]}}
                         ]
                       }
                     },
                     %{term: %{"status" => "published"}}
                   ]
                 }
               },
               %{
                 bool: %{
                   should: [
                     %{term: %{"domain_id" => 2}},
                     %{bool: %{must_not: [%{term: %{"confidential.raw" => true}}]}}
                   ]
                 }
               },
               %{term: %{"domain_id" => 1}}
             ]
    end
  end

  defp all_permissions(scope \\ :all) do
    %{
      "manage_business_concept_links" => scope,
      "manage_confidential_business_concepts" => scope,
      "view_approval_pending_business_concepts" => scope,
      "view_deprecated_business_concepts" => scope,
      "view_draft_business_concepts" => scope,
      "view_published_business_concepts" => scope,
      "view_rejected_business_concepts" => scope,
      "view_versioned_business_concepts" => scope
    }
  end
end
