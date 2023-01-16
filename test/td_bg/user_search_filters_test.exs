defmodule TdBg.UserSearchFiltersTest do
  use TdBg.DataCase

  alias TdBg.UserSearchFilters

  describe "user_search_filters" do
    alias TdBg.UserSearchFilters.UserSearchFilter

    @valid_attrs %{filters: %{}, name: "some name", user_id: 42, is_global: false}
    @invalid_attrs %{filters: nil, name: nil, user_id: nil, is_global: false}

    def user_search_filter_fixture(attrs \\ %{}) do
      {:ok, user_search_filter} =
        attrs
        |> Enum.into(@valid_attrs)
        |> UserSearchFilters.create_user_search_filter()

      user_search_filter
    end

    test "list_user_search_filters/0 returns all user_search_filters" do
      user_search_filter = user_search_filter_fixture()
      assert UserSearchFilters.list_user_search_filters() == [user_search_filter]
    end

    test "list_user_search_filters/1 includes global filters for admin user" do
      %{user_id: user_id} = claims = build(:claims, role: "admin")

      usf1 = insert(:user_search_filter, user_id: user_id)
      usf2 = insert(:user_search_filter, is_global: true)
      insert(:user_search_filter, user_id: 99)

      assert UserSearchFilters.list_user_search_filters(claims)
             |> assert_lists_equal([usf1, usf2])
    end

    test "list_user_search_filters/1 filters by taxonomy for non-admin user" do
      %{id: domain_id} = CacheHelpers.insert_domain()
      %{user_id: user_id} = claims = build(:claims, role: "user")

      CacheHelpers.put_session_permissions(claims, %{
        "view_published_business_concepts" => [domain_id]
      })

      usf1 = insert(:user_search_filter, user_id: user_id)
      usf2 = insert(:user_search_filter, is_global: true)

      usf3 =
        insert(:user_search_filter,
          is_global: true,
          filters: %{"taxonomy" => [domain_id]}
        )

      insert(:user_search_filter, is_global: true, filters: %{"taxonomy" => [99]})

      assert UserSearchFilters.list_user_search_filters(claims)
             |> assert_lists_equal([usf1, usf2, usf3])
    end

    test "get_user_search_filter!/1 returns the user_search_filter with given id" do
      user_search_filter = user_search_filter_fixture()

      assert UserSearchFilters.get_user_search_filter!(user_search_filter.id) ==
               user_search_filter
    end

    test "create_user_search_filter/1 with valid data creates a user_search_filter" do
      assert {:ok, %UserSearchFilter{} = user_search_filter} =
               UserSearchFilters.create_user_search_filter(@valid_attrs)

      assert user_search_filter.filters == %{}
      assert user_search_filter.name == "some name"
      assert user_search_filter.user_id == 42
    end

    test "create_user_search_filter/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               UserSearchFilters.create_user_search_filter(@invalid_attrs)
    end

    test "delete_user_search_filter/1 deletes the user_search_filter" do
      user_search_filter = user_search_filter_fixture()

      assert {:ok, %UserSearchFilter{}} =
               UserSearchFilters.delete_user_search_filter(user_search_filter)

      assert_raise Ecto.NoResultsError, fn ->
        UserSearchFilters.get_user_search_filter!(user_search_filter.id)
      end
    end
  end
end
