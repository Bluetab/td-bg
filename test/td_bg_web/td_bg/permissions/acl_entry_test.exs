defmodule TdBg.Permissions.AclEntryTest do
  use TdBg.DataCase

  alias TdBg.Permissions.AclEntry
  alias TdBg.Permissions.Role
  alias TdBgWeb.ApiServices.MockTdAuthService

  setup_all do
    start_supervised(MockTdAuthService)
    :ok
  end

  describe "acl_entries" do
    alias TdBg.Permissions.AclEntry

    @update_attrs %{
      principal_id: 43,
      principal_type: "user",
      resource_id: 43,
      resource_type: "domain"
    }
    @invalid_attrs %{principal_id: nil, principal_type: nil, resource_id: nil, resource_type: nil}

    def acl_entry_fixture do
      user = build(:user)
      domain = insert(:domain)
      role = Role.get_role_by_name("watch")

      acl_entry_attrs =
        insert(:acl_entry_domain_user, principal_id: user.id, resource_id: domain.id, role: role)

      acl_entry_attrs
    end

    defp get_comparable_acl_entry_fields(acl_entry) do
      Map.take(acl_entry, [
        "principal_id",
        "principal_type",
        "resource_id",
        "resource_type",
        "role_id"
      ])
    end

    test "list_acl_entries/0 returns all acl_entries" do
      acl_entry = acl_entry_fixture()
      acl_entry = get_comparable_acl_entry_fields(acl_entry)
      acl_entries = Enum.map(AclEntry.list_acl_entries(), &get_comparable_acl_entry_fields(&1))
      assert acl_entries == [acl_entry]
    end

    test "get_acl_entry!/1 returns the acl_entry with given id" do
      acl_entry = acl_entry_fixture()
      get_acl_entry = AclEntry.get_acl_entry!(acl_entry.id)

      assert get_comparable_acl_entry_fields(get_acl_entry) ==
               get_comparable_acl_entry_fields(acl_entry)
    end

    test "create_acl_entry/1 with valid data creates a acl_entry" do
      user = build(:user)
      domain = insert(:domain)
      role = Role.get_role_by_name("watch")

      valid_attrs = %{
        principal_id: user.id,
        principal_type: "user",
        resource_id: domain.id,
        resource_type: "domain",
        role_id: role.id
      }

      {:ok, acl_entry = %AclEntry{}} = AclEntry.create_acl_entry(valid_attrs)
      assert acl_entry.principal_id == user.id
      assert acl_entry.principal_type == "user"
      assert acl_entry.resource_id == domain.id
      assert acl_entry.resource_type == "domain"
      assert acl_entry.role_id == role.id
    end

    test "create_acl_entry/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = AclEntry.create_acl_entry(@invalid_attrs)
    end

    test "update_acl_entry/2 with valid data updates the acl_entry" do
      acl_entry = acl_entry_fixture()
      assert {:ok, acl_entry} = AclEntry.update_acl_entry(acl_entry, @update_attrs)
      assert %AclEntry{} = acl_entry
      assert acl_entry.principal_id == 43
      assert acl_entry.principal_type == "user"
      assert acl_entry.resource_id == 43
      assert acl_entry.resource_type == @update_attrs.resource_type
    end

    test "update_acl_entry/2 with invalid data returns error changeset" do
      acl_entry = acl_entry_fixture()
      assert {:error, %Ecto.Changeset{}} = AclEntry.update_acl_entry(acl_entry, @invalid_attrs)
      repo_acl_entry = AclEntry.get_acl_entry!(acl_entry.id)
      assert acl_entry.id == repo_acl_entry.id
      assert acl_entry.principal_type == repo_acl_entry.principal_type
      assert acl_entry.resource_id == repo_acl_entry.resource_id
      assert acl_entry.resource_type == repo_acl_entry.resource_type
      assert acl_entry.role_id == repo_acl_entry.role_id
    end

    test "delete_acl_entry/1 deletes the acl_entry" do
      acl_entry = acl_entry_fixture()
      assert {:ok, %AclEntry{}} = AclEntry.delete_acl_entry(acl_entry)
      assert_raise Ecto.NoResultsError, fn -> AclEntry.get_acl_entry!(acl_entry.id) end
    end

    test "change_acl_entry/1 returns a acl_entry changeset" do
      acl_entry = acl_entry_fixture()
      assert %Ecto.Changeset{} = AclEntry.change_acl_entry(acl_entry)
    end
  end
end
