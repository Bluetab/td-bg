defmodule TrueBG.PermissionsTest do
  use TrueBG.DataCase

  alias TrueBG.Permissions

  describe "acl_entries" do
    alias TrueBG.Permissions.AclEntry

    @valid_attrs %{principal_id: 42, principal_type: "some principal_type", resource_id: 42, resource_type: "some resource_type"}
    @update_attrs %{principal_id: 43, principal_type: "some updated principal_type", resource_id: 43, resource_type: "some updated resource_type"}
    @invalid_attrs %{principal_id: nil, principal_type: nil, resource_id: nil, resource_type: nil}

    def acl_entry_fixture(attrs \\ %{}) do
      {:ok, acl_entry} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Permissions.create_acl_entry()

      acl_entry
    end

    test "list_acl_entries/0 returns all acl_entries" do
      acl_entry = acl_entry_fixture()
      assert Permissions.list_acl_entries() == [acl_entry]
    end

    test "get_acl_entry!/1 returns the acl_entry with given id" do
      acl_entry = acl_entry_fixture()
      assert Permissions.get_acl_entry!(acl_entry.id) == acl_entry
    end

    test "create_acl_entry/1 with valid data creates a acl_entry" do
      assert {:ok, %AclEntry{} = acl_entry} = Permissions.create_acl_entry(@valid_attrs)
      assert acl_entry.principal_id == 42
      assert acl_entry.principal_type == "some principal_type"
      assert acl_entry.resource_id == 42
      assert acl_entry.resource_type == "some resource_type"
    end

    test "create_acl_entry/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Permissions.create_acl_entry(@invalid_attrs)
    end

    test "update_acl_entry/2 with valid data updates the acl_entry" do
      acl_entry = acl_entry_fixture()
      assert {:ok, acl_entry} = Permissions.update_acl_entry(acl_entry, @update_attrs)
      assert %AclEntry{} = acl_entry
      assert acl_entry.principal_id == 43
      assert acl_entry.principal_type == "some updated principal_type"
      assert acl_entry.resource_id == 43
      assert acl_entry.resource_type == "some updated resource_type"
    end

    test "update_acl_entry/2 with invalid data returns error changeset" do
      acl_entry = acl_entry_fixture()
      assert {:error, %Ecto.Changeset{}} = Permissions.update_acl_entry(acl_entry, @invalid_attrs)
      assert acl_entry == Permissions.get_acl_entry!(acl_entry.id)
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
    alias TrueBG.Permissions.Role

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
      assert length(Permissions.list_roles()) == length(Role.get_roles())
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
end
