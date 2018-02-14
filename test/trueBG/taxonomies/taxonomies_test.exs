defmodule TrueBG.TaxonomiesTest do
  use TrueBG.DataCase

  alias TrueBG.Taxonomies
  alias TrueBG.Permissions

  describe "domain_groups" do
    alias TrueBG.Taxonomies.DomainGroup
    alias TrueBG.Taxonomies.DataDomain

    @valid_attrs %{description: "some description", name: "some name"}
    @update_attrs %{description: "some updated description", name: "some updated name"}
    @invalid_attrs %{description: nil, name: nil}

    @child_attrs %{description: "child of some name description", name: "child of some name"}

    #@parent_attrs %{description: "parent description", name: "parent name"}

    def domain_group_fixture(attrs \\ %{}) do
      {:ok, domain_group} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Taxonomies.create_domain_group()
      domain_group
    end

    def acl_entry_fixture(%DomainGroup{} = domain_group) do
      user = build(:user)
      role = insert(:role)
      acl_entry_attrs = insert(:acl_entry_domain_group_user, principal_id: user.id, resource_id: domain_group.id, role: role)
      acl_entry_attrs
    end

    def acl_entry_fixture(%DataDomain{} = data_domain) do
      user = build(:user)
      role = insert(:role)
      acl_entry_attrs = insert(:acl_entry_data_domain_user, principal_id: user.id, resource_id: data_domain.id, role: role)
      acl_entry_attrs
    end

    test "list_domain_groups/0 returns all domain_groups" do
      domain_group = domain_group_fixture()
      assert Taxonomies.list_domain_groups() == [domain_group]
    end

    test "get_domain_group!/1 returns the domain_group with given id" do
      domain_group = domain_group_fixture()
      assert Taxonomies.get_domain_group!(domain_group.id) == domain_group
    end

    test "create_domain_group/1 with valid data creates a domain_group" do
      assert {:ok, %DomainGroup{} = domain_group} = Taxonomies.create_domain_group(@valid_attrs)
      assert domain_group.description == "some description"
      assert domain_group.name == "some name"
    end

    test "create_domain_group/2 child of a parent group" do
      parent_domain_group = domain_group_fixture()
      child_attrs = Map.put(@child_attrs, :parent_id, parent_domain_group.id)

      assert {:ok, %DomainGroup{} = domain_group} = Taxonomies.create_domain_group(child_attrs)
      assert domain_group.description == child_attrs.description
      assert domain_group.name == child_attrs.name
      assert domain_group.parent_id == parent_domain_group.id
    end

    test "create_domain_group/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Taxonomies.create_domain_group(@invalid_attrs)
    end

    test "update_domain_group/2 with valid data updates the domain_group" do
      domain_group = domain_group_fixture()
      assert {:ok, domain_group} = Taxonomies.update_domain_group(domain_group, @update_attrs)
      assert %DomainGroup{} = domain_group
      assert domain_group.description == "some updated description"
      assert domain_group.name == "some updated name"
    end

    test "update_domain_group/2 with invalid data returns error changeset" do
      domain_group = domain_group_fixture()
      assert {:error, %Ecto.Changeset{}} = Taxonomies.update_domain_group(domain_group, @invalid_attrs)
      assert domain_group == Taxonomies.get_domain_group!(domain_group.id)
    end

    test "delete_domain_group/1 deletes the domain_group" do
      domain_group = domain_group_fixture()
      assert {:ok, %DomainGroup{}} = Taxonomies.delete_domain_group(domain_group)
      assert_raise Ecto.NoResultsError, fn -> Taxonomies.get_domain_group!(domain_group.id) end
    end

    test "delete acl_entries when deleting domain_group with acl_entries" do
      domain_group = domain_group_fixture()
      acl_entry = acl_entry_fixture(domain_group)
      assert {:ok, %DomainGroup{}} = Taxonomies.delete_domain_group(domain_group)
      assert_raise Ecto.NoResultsError, fn -> Permissions.get_acl_entry!(acl_entry.id) == nil end
      assert_raise Ecto.NoResultsError, fn -> Taxonomies.get_domain_group!(domain_group.id) end
    end

    test "change_domain_group/1 returns a domain_group changeset" do
      domain_group = domain_group_fixture()
      assert %Ecto.Changeset{} = Taxonomies.change_domain_group(domain_group)
    end
  end

  describe "data_domains" do
    alias TrueBG.Taxonomies.DataDomain

    @valid_attrs %{description: "some description", name: "some name"}
    @update_attrs %{description: "some updated description", name: "some updated name"}
    @invalid_attrs %{description: nil, name: nil}

    def data_domain_fixture(attrs \\ %{}) do
      {:ok, data_domain} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Taxonomies.create_data_domain()

      data_domain
    end

    test "list_data_domains/0 returns all data_domains" do
      data_domain = data_domain_fixture()
      assert Taxonomies.list_data_domains() == [data_domain]
    end

    test "get_data_domain!/1 returns the data_domain with given id" do
      data_domain = data_domain_fixture()
      assert Taxonomies.get_data_domain!(data_domain.id) == data_domain
    end

    test "create_data_domain/1 with valid data creates a data_domain" do
      assert {:ok, %DataDomain{} = data_domain} = Taxonomies.create_data_domain(@valid_attrs)
      assert data_domain.description == "some description"
      assert data_domain.name == "some name"
    end

    test "create_data_domain/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Taxonomies.create_data_domain(@invalid_attrs)
    end

    test "update_data_domain/2 with valid data updates the data_domain" do
      data_domain = data_domain_fixture()
      assert {:ok, data_domain} = Taxonomies.update_data_domain(data_domain, @update_attrs)
      assert %DataDomain{} = data_domain
      assert data_domain.description == "some updated description"
      assert data_domain.name == "some updated name"
    end

    test "update_data_domain/2 with invalid data returns error changeset" do
      data_domain = data_domain_fixture()
      assert {:error, %Ecto.Changeset{}} = Taxonomies.update_data_domain(data_domain, @invalid_attrs)
      assert data_domain == Taxonomies.get_data_domain!(data_domain.id)
    end

    test "delete_data_domain/1 deletes the data_domain" do
      data_domain = data_domain_fixture()
      assert {:ok, %DataDomain{}} = Taxonomies.delete_data_domain(data_domain)
      assert_raise Ecto.NoResultsError, fn -> Taxonomies.get_data_domain!(data_domain.id) end
    end

    test "delete acl_entries when deleting data_domain with acl_entries" do
      data_domain = data_domain_fixture()
      acl_entry = acl_entry_fixture(data_domain)
      assert {:ok, %DataDomain{}} = Taxonomies.delete_data_domain(data_domain)
      assert_raise Ecto.NoResultsError, fn -> Permissions.get_acl_entry!(acl_entry.id) == nil end
      assert_raise Ecto.NoResultsError, fn -> Taxonomies.get_data_domain!(data_domain.id) end
    end

    test "change_data_domain/1 returns a data_domain changeset" do
      data_domain = data_domain_fixture()
      assert %Ecto.Changeset{} = Taxonomies.change_data_domain(data_domain)
    end
  end
end
