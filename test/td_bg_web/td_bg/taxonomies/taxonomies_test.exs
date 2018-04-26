defmodule TdBg.TaxonomiesTest do
  use TdBg.DataCase

  alias TdBg.Taxonomies
  alias TdBg.Permissions

  describe "domains" do
    alias TdBg.Taxonomies.Domain

    @valid_attrs %{description: "some description", name: "some name"}
    @update_attrs %{description: "some updated description", name: "some updated name"}
    @invalid_attrs %{description: nil, name: nil}

    @child_attrs %{description: "child of some name description", name: "child of some name"}

    #@parent_attrs %{description: "parent description", name: "parent name"}

    def domain_fixture(attrs \\ %{}) do
      {:ok, domain} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Taxonomies.create_domain()
      domain
    end

    def acl_entry_fixture(%Domain{} = domain) do
      user = build(:user)
      role = Permissions.get_role_by_name("watch")
      acl_entry_attrs = insert(:acl_entry_domain_user, principal_id: user.id, resource_id: domain.id, role: role)
      acl_entry_attrs
    end

    test "list_domains/0 returns all domains" do
      domain = domain_fixture()
      assert Taxonomies.list_domains() == [domain]
    end

    test "get_domain!/1 returns the domain with given id" do
      domain = domain_fixture()
      assert Taxonomies.get_domain!(domain.id) == domain
    end

    test "create_domain/1 with valid data creates a domain" do
      assert {:ok, %Domain{} = domain} = Taxonomies.create_domain(@valid_attrs)
      assert domain.description == "some description"
      assert domain.name == "some name"
    end

    test "create_domain/2 child of a parent domain" do
      parent_domain = domain_fixture()
      child_attrs = Map.put(@child_attrs, :parent_id, parent_domain.id)

      assert {:ok, %Domain{} = domain} = Taxonomies.create_domain(child_attrs)
      assert domain.description == child_attrs.description
      assert domain.name == child_attrs.name
      assert domain.parent_id == parent_domain.id
    end

    test "create_domain/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Taxonomies.create_domain(@invalid_attrs)
    end

    test "update_domain/2 with valid data updates the domain" do
      domain = domain_fixture()
      assert {:ok, domain} = Taxonomies.update_domain(domain, @update_attrs)
      assert %Domain{} = domain
      assert domain.description == "some updated description"
      assert domain.name == "some updated name"
    end

    test "update_domain/2 with invalid data returns error changeset" do
      domain = domain_fixture()
      assert {:error, %Ecto.Changeset{}} = Taxonomies.update_domain(domain, @invalid_attrs)
      assert domain == Taxonomies.get_domain!(domain.id)
    end

    test "delete_domain/1 deletes the domain" do
      domain = domain_fixture()
      assert {:ok, %Domain{}} = Taxonomies.delete_domain(domain)
      assert_raise Ecto.NoResultsError, fn -> Taxonomies.get_domain!(domain.id) end
    end

    test "delete_domain/1 deletes the domain an create the same domain" do
      assert {:ok, %Domain{} = domain} = Taxonomies.create_domain(@valid_attrs)
      assert {:ok, %Domain{}} = Taxonomies.delete_domain(domain)
      assert {:ok, %Domain{}} = Taxonomies.create_domain(@valid_attrs)
    end

    test "delete acl_entries when deleting domain with acl_entries" do
      domain = domain_fixture()
      acl_entry = acl_entry_fixture(domain)
      assert {:ok, %Domain{}} = Taxonomies.delete_domain(domain)
      assert_raise Ecto.NoResultsError, fn -> Permissions.get_acl_entry!(acl_entry.id) == nil end
      assert_raise Ecto.NoResultsError, fn -> Taxonomies.get_domain!(domain.id) end
    end

    test "change_domain/1 returns a domain changeset" do
      domain = domain_fixture()
      assert %Ecto.Changeset{} = Taxonomies.change_domain(domain)
    end
  end

end
