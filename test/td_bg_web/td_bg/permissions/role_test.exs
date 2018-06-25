defmodule TdBg.Permissions.RoleTest do
  use TdBg.DataCase

  alias TdBg.Permissions
  alias TdBg.Permissions.Role
  alias TdBgWeb.ApiServices.MockTdAuthService

  setup_all do
    start_supervised(MockTdAuthService)
    :ok
  end

  describe "roles" do
    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def role_fixture(attrs \\ %{}) do
      {:ok, role} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Role.create_role()

      role
    end

    test "list_roles/0 returns all roles" do
      # admin, watch, create, publish
      assert length(Role.list_roles()) == 4
    end

    test "get_role!/1 returns the role with given id" do
      role = role_fixture()
      assert Role.get_role!(role.id) == role
    end

    test "create_role/1 with valid data creates a role" do
      assert {:ok, %Role{} = role} = Role.create_role(@valid_attrs)
      assert role.name == "some name"
    end

    test "create_role/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Role.create_role(@invalid_attrs)
    end

    test "update_role/2 with valid data updates the role" do
      role = role_fixture()
      assert {:ok, role} = Role.update_role(role, @update_attrs)
      assert %Role{} = role
      assert role.name == "some updated name"
    end

    test "update_role/2 with invalid data returns error changeset" do
      role = role_fixture()
      assert {:error, %Ecto.Changeset{}} = Role.update_role(role, @invalid_attrs)
      assert role == Role.get_role!(role.id)
    end

    test "delete_role/1 deletes the role" do
      role = role_fixture()
      assert {:ok, %Role{}} = Role.delete_role(role)
      assert_raise Ecto.NoResultsError, fn -> Role.get_role!(role.id) end
    end

    test "change_role/1 returns a role changeset" do
      role = role_fixture()
      assert %Ecto.Changeset{} = Role.change_role(role)
    end
  end

  describe "role permissions" do
    @role_attrs %{name: "rolename"}

    test "get_role_permissions/0 returns all roles" do
      admin = Role.get_role_by_name("admin")
      assert length(Role.get_role_permissions(admin)) != 0
    end

    test "add_permissions_to_role/2 adds permissions to a role" do
      Role.create_role(@role_attrs)

      permissions = Permissions.list_permissions()
      permissions = Enum.sort(permissions, &(&1.name < &2.name))

      role = Role.get_role_by_name(@role_attrs.name)
      Role.add_permissions_to_role(role, permissions)

      role = Role.get_role_by_name(@role_attrs.name)
      stored_permissions = Role.get_role_permissions(role)
      stored_permissions = Enum.sort(stored_permissions, &(&1.name < &2.name))

      assert permissions == stored_permissions
    end

    test "add_permissions_to_role/2 delete all permissions" do
      Role.create_role(@role_attrs)

      permissions = Permissions.list_permissions()
      permissions = Enum.sort(permissions, &(&1.name < &2.name))

      role = Role.get_role_by_name(@role_attrs.name)
      Role.add_permissions_to_role(role, permissions)

      role = Role.get_role_by_name(@role_attrs.name)
      stored_permissions = Role.get_role_permissions(role)
      stored_permissions = Enum.sort(stored_permissions, &(&1.name < &2.name))

      assert permissions == stored_permissions

      role = Role.get_role_by_name(@role_attrs.name)
      Role.add_permissions_to_role(role, [])

      role = Role.get_role_by_name(@role_attrs.name)
      stored_permissions = Role.get_role_permissions(role)

      assert [] == stored_permissions
    end
  end
end
