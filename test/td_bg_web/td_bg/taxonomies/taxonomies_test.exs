defmodule TdBg.TaxonomiesTest do
  use TdBg.DataCase

  alias TdBg.Taxonomies

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

    test "list_domains/0 returns all domains" do
      domain = domain_fixture()
      [h|t] = Taxonomies.list_domains()
      assert t == []
      assert Map.drop(h, [:parent]) == Map.drop(domain, [:parent])
    end

    test "get_domain!/1 returns the domain with given id" do
      domain = domain_fixture()
      assert Taxonomies.get_domain!(domain.id) == domain
    end

    test "get_children_domains/1 returns the children domain of a domain" do
      parent = insert(:domain)
      children = Enum.reduce([0, 1, 2], [], &([insert(:child_domain, name: "d#{&1}", parent: parent)|&2]))
      domains = Taxonomies.get_children_domains(parent)
      sodocd_domains = Enum.reverse(Enum.sort_by(domains, &(&1.id)))
      assert length(sodocd_domains) == 3
      Enum.each(0..2, fn(i) ->
        assert Enum.at(children, i).name == Enum.at(sodocd_domains, i).name
      end)
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

    # TODO test "delete acl_entries when deleting domain with acl_entries"

    test "change_domain/1 returns a domain changeset" do
      domain = domain_fixture()
      assert %Ecto.Changeset{} = Taxonomies.change_domain(domain)
    end

    test "get_domain_ancestors/2 returns the list of a domain's ancestors" do
      d1 = domain_fixture(%{name: "d1"})
      d2 = domain_fixture(%{parent_id: d1.id, name: "d2"})
      d3 = domain_fixture(%{parent_id: d2.id, name: "d3"})
      d4 = domain_fixture(%{parent_id: d3.id, name: "d4"})
      ancestors_with_self = Taxonomies.get_domain_ancestors(d4, true)
      ancestors_without_self = Taxonomies.get_domain_ancestors(d4, false)
      assert ancestors_with_self |> Enum.map(&(&1.id)) == [d4, d3, d2, d1] |> Enum.map(&(&1.id))
      assert ancestors_without_self |> Enum.map(&(&1.id)) == [d3, d2, d1] |> Enum.map(&(&1.id))
    end

    test "search_fields/1 includes the list of parent_ids" do
      d1 = domain_fixture(%{name: "d1"})
      d2 = domain_fixture(%{parent_id: d1.id, name: "d2"})
      d3 = domain_fixture(%{parent_id: d2.id, name: "d3"})
      d4 = domain_fixture(%{parent_id: d3.id, name: "d4"})
      search_fields = Domain.search_fields(d4)
      assert search_fields.parent_ids == [d3.id, d2.id, d1.id]
    end

    test "get_ancestors_for_domain_id/2 returns the list of a domain's ancestors" do
      d1 = domain_fixture(%{name: "d1"})
      d2 = domain_fixture(%{parent_id: d1.id, name: "d2"})
      d3 = domain_fixture(%{parent_id: d2.id, name: "d3"})
      d4 = domain_fixture(%{parent_id: d3.id, name: "d4"})
      ancestors_with_self = Taxonomies.get_ancestors_for_domain_id(d4.id, true)
      ancestors_without_self = Taxonomies.get_ancestors_for_domain_id(d4.id, false)
      assert ancestors_with_self |> Enum.map(&(&1.id)) == [d4, d3, d2, d1] |> Enum.map(&(&1.id))
      assert ancestors_without_self |> Enum.map(&(&1.id)) == [d3, d2, d1] |> Enum.map(&(&1.id))
    end
  end

end
