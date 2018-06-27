defmodule TdBg.PermissionsTest do
  use TdBg.DataCase

  alias TdBg.Permissions
  alias TdBg.Permissions.Permission
  alias TdBgWeb.ApiServices.MockTdAuthService

  import TdBgWeb.Authentication, only: :functions

  setup_all do
    start_supervised(MockTdAuthService)
    :ok
  end

  describe "permissions" do
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

    test "get_permissions_in_resource?/1 get permissions in resource" do
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

      assert Permissions.authorized?(user, permission.name, domain.id)

      assert !Permissions.authorized?(user, "notienepermiso", domain.id)
    end
  end
end
