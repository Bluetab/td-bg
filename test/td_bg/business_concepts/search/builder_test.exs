defmodule TdBg.BusinessConcepts.Search.QueryBuilderTest do
  use ExUnit.Case

  alias TdBg.BusinessConcepts.Search.QueryBuilder

  describe "status_filter/2" do
    test "returns a boolean query with a must_not clause to filter forbidden statuses" do
      assert %{bool: bool} = QueryBuilder.status_filter(%{})

      assert bool == %{
               must_not: [
                 %{
                   terms: %{
                     "status" => [
                       "deprecated",
                       "draft",
                       "pending_approval",
                       "published",
                       "rejected",
                       "versioned"
                     ]
                   }
                 }
               ]
             }
    end

    test "returns a match_all query if default scope is all and permissions are empty" do
      assert QueryBuilder.status_filter(%{}, :all) == %{match_all: %{}}
    end

    test "returns a terms query to filter permitted statuses" do
      assert QueryBuilder.status_filter(%{
               "view_draft_business_concepts" => :all,
               "view_published_business_concepts" => :all
             }) == %{terms: %{"status" => ["draft", "published"]}}
    end

    test "returns a boolean query to filter by status and domain_ids" do
      assert QueryBuilder.status_filter(%{
               "view_draft_business_concepts" => [1],
               "view_published_business_concepts" => [1]
             }) == %{
               bool: %{
                 filter: [
                   %{terms: %{"status" => ["draft", "published"]}},
                   %{term: %{"domain_id" => 1}}
                 ]
               }
             }
    end

    test "returns a boolean query with a should clause for each group of scope and status" do
      assert QueryBuilder.status_filter(%{
               "view_approval_pending_business_concepts" => [3],
               "view_draft_business_concepts" => [1, 2, 3],
               "view_published_business_concepts" => :all,
               "view_rejected_business_concepts" => [3]
             }) == %{
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

  describe "confidential_filter/2" do
    test "includes a must_not clause on the confidential.raw field" do
      assert %{bool: bool} = QueryBuilder.confidential_filter(%{})
      assert bool == %{must_not: [%{term: %{"confidential.raw" => true}}]}
    end

    test "returns nil if the default scope is all" do
      assert QueryBuilder.confidential_filter(%{}, :all) == nil
    end

    test "includes a should clause if the scope is a list of domain ids" do
      assert %{bool: bool} =
               QueryBuilder.confidential_filter(%{
                 "manage_confidential_business_concepts" => [1, 2]
               })

      assert bool == %{
               should: [
                 %{terms: %{"domain_id" => [1, 2]}},
                 %{bool: %{must_not: [%{term: %{"confidential.raw" => true}}]}}
               ]
             }
    end
  end

  describe "links_filter/2" do
    test "returns a match_none query by default" do
      assert QueryBuilder.links_filter(%{}) == %{match_none: %{}}
    end

    test "returns nil if the default scope is all" do
      assert QueryBuilder.links_filter(%{}, :all) == nil
    end

    test "returns a terms query if the scope is a list of domain ids" do
      assert QueryBuilder.links_filter(%{"manage_business_concept_links" => [1, 2]}) ==
               %{terms: %{"domain_id" => [1, 2]}}
    end
  end

  describe "build_filters/2" do
    test "returns a bool query with must_not clauses on status and confidential" do
      assert QueryBuilder.build_filters(%{}) == [
               %{
                 bool: %{
                   must_not: [
                     %{
                       terms: %{
                         "status" => [
                           "deprecated",
                           "draft",
                           "pending_approval",
                           "published",
                           "rejected",
                           "versioned"
                         ]
                       }
                     }
                   ]
                 }
               },
               %{bool: %{must_not: [%{term: %{"confidential.raw" => true}}]}}
             ]
    end

    test "returns a match_all query if default scope is all and permissions are empty" do
      assert [%{match_all: %{}}] = QueryBuilder.build_filters(%{}, default_scope: :all)
    end

    test "returns a filter by domain id, status and linkable" do
      assert QueryBuilder.build_filters(
               %{
                 "view_published_business_concepts" => :all,
                 "view_draft_business_concepts" => [1, 2],
                 "manage_confidential_business_concepts" => [2],
                 "manage_business_concept_links" => [1]
               },
               linkable: true
             ) == [
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
end
