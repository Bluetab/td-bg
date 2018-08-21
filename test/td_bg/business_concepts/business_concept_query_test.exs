defmodule TdBg.BusinessConceptQueryTest do
  use TdBg.DataCase
  alias TdBg.BusinessConcept.Query

  describe "business_concepts_query" do

    test "add_query_wildcard/1 Miscellaneous" do
      assert "my blah*" == Query.add_query_wildcard("my blah")

      assert "my \"blah\"" == Query.add_query_wildcard("my \"blah\"")
      assert "my blah\""   == Query.add_query_wildcard("my blah\"")
      assert "my \"blah*"  == Query.add_query_wildcard("my \"blah")

      assert "my (blah)" == Query.add_query_wildcard("my (blah)")
      assert "my blah)"  == Query.add_query_wildcard("my blah)")
      assert "my (blah*" == Query.add_query_wildcard("my (blah")

      assert "my " == Query.add_query_wildcard("my ")

    end

  end
end
