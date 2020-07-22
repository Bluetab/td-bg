defmodule TdBg.GroupsTest do
  use TdBg.DataCase

  alias TdBg.Groups

  describe "domain_groups" do
    alias TdBg.Groups.DomainGroup

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def domain_group_fixture(attrs \\ %{}) do
      {:ok, domain_group} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Groups.create_domain_group()

      domain_group
    end

    test "list_domain_groups/0 returns all domain_groups" do
      domain_group = domain_group_fixture()
      assert Groups.list_domain_groups() == [domain_group]
    end

    test "get_domain_group!/1 returns the domain_group with given id" do
      domain_group = domain_group_fixture()
      assert Groups.get_domain_group!(domain_group.id) == domain_group
    end

    test "create_domain_group/1 with valid data creates a domain_group" do
      assert {:ok, %DomainGroup{} = domain_group} = Groups.create_domain_group(@valid_attrs)
      assert domain_group.name == "some name"
    end

    test "create_domain_group/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Groups.create_domain_group(@invalid_attrs)
    end

    test "create_domain_group/1 with duplicated name gives an error" do
      domain_group = domain_group_fixture()
      assert {:error, %Ecto.Changeset{}} = Groups.create_domain_group(%{name: domain_group.name})
    end

    test "update_domain_group/2 with valid data updates the domain_group" do
      domain_group = domain_group_fixture()

      assert {:ok, %DomainGroup{} = domain_group} =
               Groups.update_domain_group(domain_group, @update_attrs)

      assert domain_group.name == "some updated name"
    end

    test "update_domain_group/2 with invalid data returns error changeset" do
      domain_group = domain_group_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Groups.update_domain_group(domain_group, @invalid_attrs)

      assert domain_group == Groups.get_domain_group!(domain_group.id)
    end

    test "delete_domain_group/1 deletes the domain_group" do
      domain_group = domain_group_fixture()
      assert {:ok, %DomainGroup{}} = Groups.delete_domain_group(domain_group)
      assert_raise Ecto.NoResultsError, fn -> Groups.get_domain_group!(domain_group.id) end
    end

    test "change_domain_group/1 returns a domain_group changeset" do
      domain_group = domain_group_fixture()
      assert %Ecto.Changeset{} = Groups.change_domain_group(domain_group)
    end
  end
end
