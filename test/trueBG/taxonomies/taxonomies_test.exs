defmodule TrueBG.TaxonomiesTest do
  use TrueBG.DataCase

  alias TrueBG.Taxonomies

  describe "domain_groups" do
    alias TrueBG.Taxonomies.DomainGroup

    @valid_attrs %{description: "some description", name: "some name"}
    @update_attrs %{description: "some updated description", name: "some updated name"}
    @invalid_attrs %{description: nil, name: nil}

    def domain_group_fixture(attrs \\ %{}) do
      {:ok, domain_group} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Taxonomies.create_domain_group()

      domain_group
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

    test "change_domain_group/1 returns a domain_group changeset" do
      domain_group = domain_group_fixture()
      assert %Ecto.Changeset{} = Taxonomies.change_domain_group(domain_group)
    end
  end
end
