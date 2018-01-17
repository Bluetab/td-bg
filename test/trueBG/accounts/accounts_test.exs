defmodule TrueBG.AccountsTest do
  use TrueBG.DataCase

  alias TrueBG.Accounts

  describe "users" do
    alias TrueBG.Accounts.User

    @valid_attrs %{password_hash: "some password_hash", user_name: "some user_name"}
    @update_attrs %{password_hash: "some updated password_hash", user_name: "some updated user_name"}
    @invalid_attrs %{password_hash: nil, user_name: nil}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_user()

      user
    end

    # TODO: list all users with admin user
    # test "list_users/0 returns all users" do
    #   user = user_fixture()
    #   assert Accounts.list_users() == [user]
    # end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end
    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)

      assert user.password_hash == "some password_hash"
      assert user.user_name == "some user_name"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, user} = Accounts.update_user(user, @update_attrs)
      assert %User{} = user
      assert user.password_hash == "some updated password_hash"
      assert user.user_name == "some updated user_name"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end

    test "get_user_by_name/1 return the user with given user_name" do
      user = user_fixture()
      assert Accounts.get_user_by_name(user.user_name) == user
    end
  end
end
