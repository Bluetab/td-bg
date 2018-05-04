defmodule TdBg.PermissionsTest do
  use TdBg.DataCase

  alias TdBg.Permissions
  alias TdBgWeb.ApiServices.MockTdAuthService

  import TdBgWeb.Authentication, only: :functions

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  describe "permissions" do
    alias TdBg.Permissions.Permission

    test "list_permissions/0 returns all permissions" do
      current_permissions = Permission.permissions |> Map.values |> Enum.sort
      stored_permissions  = Permissions.list_permissions() |> Enum.map(&Map.get(&1, :name)) |> Enum.sort
      assert current_permissions == stored_permissions
    end

    test "get_permission!/1 returns the premission with given id" do
      permission = List.first(Permissions.list_permissions())
      assert Permissions.get_permission!(permission.id) == permission
    end
  end

  describe "acl_entries" do
    alias TdBg.Permissions.AclEntry

    @update_attrs %{principal_id: 43, principal_type: "user", resource_id: 43, resource_type: "domain"}
    @invalid_attrs %{principal_id: nil, principal_type: nil, resource_id: nil, resource_type: nil}

    def acl_entry_fixture do
      user = build(:user)
      domain = insert(:domain)
      role = Permissions.get_role_by_name("watch")
      acl_entry_attrs = insert(:acl_entry_domain_user, principal_id: user.id, resource_id: domain.id, role: role)
      acl_entry_attrs
    end

    defp get_comparable_acl_entry_fields(acl_entry) do
      Map.take(acl_entry, ["principal_id", "principal_type", "resource_id", "resource_type", "role_id"])
    end

    test "list_acl_entries/0 returns all acl_entries" do
      acl_entry = acl_entry_fixture()
      acl_entry = get_comparable_acl_entry_fields(acl_entry)
      acl_entries = Enum.map(Permissions.list_acl_entries(), &(get_comparable_acl_entry_fields(&1)))
      assert acl_entries == [acl_entry]
    end

    test "get_acl_entry!/1 returns the acl_entry with given id" do
      acl_entry = acl_entry_fixture()
      get_acl_entry = Permissions.get_acl_entry!(acl_entry.id)
      assert get_comparable_acl_entry_fields(get_acl_entry)  == get_comparable_acl_entry_fields(acl_entry)
    end

    test "create_acl_entry/1 with valid data creates a acl_entry" do
      user = build(:user)
      domain = insert(:domain)
      role = Permissions.get_role_by_name("watch")
      valid_attrs = %{principal_id: user.id, principal_type: "user", resource_id: domain.id, resource_type: "domain", role_id: role.id}
      {:ok, acl_entry = %AclEntry{}} = Permissions.create_acl_entry(valid_attrs)
      assert acl_entry.principal_id == user.id
      assert acl_entry.principal_type == "user"
      assert acl_entry.resource_id == domain.id
      assert acl_entry.resource_type == "domain"
      assert acl_entry.role_id == role.id
    end

    test "create_acl_entry/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Permissions.create_acl_entry(@invalid_attrs)
    end

    test "update_acl_entry/2 with valid data updates the acl_entry" do
      acl_entry = acl_entry_fixture()
      assert {:ok, acl_entry} = Permissions.update_acl_entry(acl_entry, @update_attrs)
      assert %AclEntry{} = acl_entry
      assert acl_entry.principal_id == 43
      assert acl_entry.principal_type == "user"
      assert acl_entry.resource_id == 43
      assert acl_entry.resource_type == @update_attrs.resource_type
    end

    test "update_acl_entry/2 with invalid data returns error changeset" do
      acl_entry = acl_entry_fixture()
      assert {:error, %Ecto.Changeset{}} = Permissions.update_acl_entry(acl_entry, @invalid_attrs)
      repo_acl_entry = Permissions.get_acl_entry!(acl_entry.id)
      assert acl_entry.id == repo_acl_entry.id
      assert acl_entry.principal_type == repo_acl_entry.principal_type
      assert acl_entry.resource_id == repo_acl_entry.resource_id
      assert acl_entry.resource_type == repo_acl_entry.resource_type
      assert acl_entry.role_id == repo_acl_entry.role_id
    end

    test "delete_acl_entry/1 deletes the acl_entry" do
      acl_entry = acl_entry_fixture()
      assert {:ok, %AclEntry{}} = Permissions.delete_acl_entry(acl_entry)
      assert_raise Ecto.NoResultsError, fn -> Permissions.get_acl_entry!(acl_entry.id) end
    end

    test "change_acl_entry/1 returns a acl_entry changeset" do
      acl_entry = acl_entry_fixture()
      assert %Ecto.Changeset{} = Permissions.change_acl_entry(acl_entry)
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
      assert length(Permissions.list_roles()) == 4 # admin, watch, create, publish
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
    alias TdBg.Permissions.Role
    alias TdBg.Permissions.Permission

    @role_attrs %{name: "rolename"}

    test "get_role_permissions/0 returns all roles" do
      admin = Permissions.get_role_by_name("admin")
      assert length(Permissions.get_role_permissions(admin)) != 0
    end

    test "add_permissions_to_role/2 adds permissions to a role" do
      Permissions.create_role(@role_attrs)

      permissions = Permissions.list_permissions
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

      permissions = Permissions.list_permissions
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
      assert Permissions.get_permissions_in_resource(%{user_id: user.id, domain_id: domain.id}) == [permission.name]
    end

    test "authorize?/1 check permission" do
      user = build(:user)
      user = create_user(user.user_name)
      domain = insert(:domain)
      permission = insert(:permission)
      role = insert(:role, permissions: [permission])
      insert(:acl_entry_domain_user, principal_id: user.id, resource_id: domain.id, role: role)
      assert Permissions.authorized?(%{user_id: user.id, domain_id: domain.id, permission: permission.name})
      assert !Permissions.authorized?(%{user_id: user.id, domain_id: domain.id, permission: "notienepermiso"})
    end
  end
end
