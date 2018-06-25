defmodule TdBg.PermissionsTest do
  use TdBg.DataCase

  alias TdBg.Permissions
  alias TdBgWeb.ApiServices.MockTdAuthService

  import TdBgWeb.Authentication, only: :functions

  setup_all do
    start_supervised(MockTdAuthService)
    :ok
  end

  describe "permissions" do
    alias TdBg.Permissions.Permission

    test "list_permissions/0 returns all permissions" do
      current_permissions = Permission.permissions() |> Map.values() |> Enum.sort()

      stored_permissions =
        Permissions.list_permissions() |> Enum.map(&Map.get(&1, :name)) |> Enum.sort()

      assert current_permissions == stored_permissions
    end

    test "get_permission!/1 returns the premission with given id" do
      permission = List.first(Permissions.list_permissions())
      assert Permissions.get_permission!(permission.id) == permission
    end
  end

  describe "roles" do
    alias TdBg.Permissions.Role

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def role_fixture(attrs \\ %{}) do
      {:ok, role} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Permissions.create_role()

      role
    end

    test "list_roles/0 returns all roles" do
      # admin, watch, create, publish
      assert length(Permissions.list_roles()) == 4
    end

    test "get_role!/1 returns the role with given id" do
      role = role_fixture()
      assert Permissions.get_role!(role.id) == role
    end

    test "create_role/1 with valid data creates a role" do
      assert {:ok, %Role{} = role} = Permissions.create_role(@valid_attrs)
      assert role.name == "some name"
    end

    test "create_role/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Permissions.create_role(@invalid_attrs)
    end

    test "update_role/2 with valid data updates the role" do
      role = role_fixture()
      assert {:ok, role} = Permissions.update_role(role, @update_attrs)
      assert %Role{} = role
      assert role.name == "some updated name"
    end

    test "update_role/2 with invalid data returns error changeset" do
      role = role_fixture()
      assert {:error, %Ecto.Changeset{}} = Permissions.update_role(role, @invalid_attrs)
      assert role == Permissions.get_role!(role.id)
    end

    test "delete_role/1 deletes the role" do
      role = role_fixture()
      assert {:ok, %Role{}} = Permissions.delete_role(role)
      assert_raise Ecto.NoResultsError, fn -> Permissions.get_role!(role.id) end
    end

    test "change_role/1 returns a role changeset" do
      role = role_fixture()
      assert %Ecto.Changeset{} = Permissions.change_role(role)
    end
  end

  describe "role permissions" do
    alias TdBg.Permissions.Permission
    alias TdBg.Permissions.Role

    @role_attrs %{name: "rolename"}

    test "get_role_permissions/0 returns all roles" do
      admin = Permissions.get_role_by_name("admin")
      assert length(Permissions.get_role_permissions(admin)) != 0
    end

    test "add_permissions_to_role/2 adds permissions to a role" do
      Permissions.create_role(@role_attrs)

      permissions = Permissions.list_permissions()
      permissions = Enum.sort(permissions, &(&1.name < &2.name))

      role = Permissions.get_role_by_name(@role_attrs.name)
      Permissions.add_permissions_to_role(role, permissions)

      role = Permissions.get_role_by_name(@role_attrs.name)
      stored_permissions = Permissions.get_role_permissions(role)
      stored_permissions = Enum.sort(stored_permissions, &(&1.name < &2.name))

      assert permissions == stored_permissions
    end

    test "add_permissions_to_role/2 delete all permissions" do
      Permissions.create_role(@role_attrs)

      permissions = Permissions.list_permissions()
      permissions = Enum.sort(permissions, &(&1.name < &2.name))

      role = Permissions.get_role_by_name(@role_attrs.name)
      Permissions.add_permissions_to_role(role, permissions)

      role = Permissions.get_role_by_name(@role_attrs.name)
      stored_permissions = Permissions.get_role_permissions(role)
      stored_permissions = Enum.sort(stored_permissions, &(&1.name < &2.name))

      assert permissions == stored_permissions

      role = Permissions.get_role_by_name(@role_attrs.name)
      Permissions.add_permissions_to_role(role, [])

      role = Permissions.get_role_by_name(@role_attrs.name)
      stored_permissions = Permissions.get_role_permissions(role)

      assert [] == stored_permissions
    end

    test "get_permissios_in_resource?/1 get permissions in resource" do
      user = build(:user)
      user = create_user(user.user_name)
      domain = insert(:domain)
      permission = insert(:permission)
      role = insert(:role, permissions: [permission])
      insert(:acl_entry_domain_user, principal_id: user.id, resource_id: domain.id, role: role)

      assert Permissions.get_permissions_in_resource(%{user_id: user.id, domain_id: domain.id}) ==
               [permission.name]
    end

    test "authorize?/1 check permission" do
      user = build(:user)
      user = create_user(user.user_name)
      domain = insert(:domain)
      permission = insert(:permission)
      role = insert(:role, permissions: [permission])
      insert(:acl_entry_domain_user, principal_id: user.id, resource_id: domain.id, role: role)

      assert Permissions.authorized?(%{
               user_id: user.id,
               domain_id: domain.id,
               permission: permission.name
             })

      assert !Permissions.authorized?(%{
               user_id: user.id,
               domain_id: domain.id,
               permission: "notienepermiso"
             })
    end
  end
end
