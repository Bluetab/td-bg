defmodule TdBg.TaxonomiesTest do
  use TdBg.DataCase

  alias TdBg.Cache.DomainLoader
  alias TdBg.Groups
  alias TdBg.Repo
  alias TdBg.Search.IndexWorker
  alias TdBg.Taxonomies
  alias TdBg.Taxonomies.Domain

  setup_all do
    start_supervised(DomainLoader)
    start_supervised(IndexWorker)
    :ok
  end

  describe "domains" do
    test "list_domains/0 returns all domains" do
      %{id: id} = insert(:domain)
      assert [%{id: ^id}] = Taxonomies.list_domains()
    end

    test "get_domain!/1 returns the domain with given id" do
      %{id: id} = domain = insert(:domain)
      assert Taxonomies.get_domain!(id) == domain
    end

    test "get_children_domains/1 returns the children domain of a domain" do
      parent = insert(:domain)

      children = Enum.map(0..2, fn _ -> insert(:domain, parent: parent) end)

      domains =
        parent
        |> Taxonomies.get_children_domains()
        |> Enum.sort_by(& &1.id)

      assert Enum.map(domains, & &1.id) == Enum.map(children, & &1.id)
    end

    test "create_domain/1 with valid data creates a domain" do
      %{name: name, description: description, external_id: external_id} =
        params =
        build(:domain)
        |> Map.take([:name, :description, :external_id])

      assert {:ok, domain} = Taxonomies.create_domain(params)
      assert %Domain{name: ^name, description: ^description, external_id: ^external_id} = domain
    end

    test "create_domain/1 child of a parent domain" do
      %{id: parent_id} = insert(:domain)

      %{name: name, description: description, external_id: external_id, parent_id: ^parent_id} =
        params =
        build(:domain, parent_id: parent_id)
        |> Map.take([:name, :description, :external_id, :parent_id])

      assert {:ok, domain} = Taxonomies.create_domain(params)

      assert %Domain{
               parent_id: ^parent_id,
               name: ^name,
               description: ^description,
               external_id: ^external_id
             } = domain
    end

    test "create_domain/1 child of a parent domain will inherit its parent group" do
      group = insert(:domain_group)
      %{id: domain_group_id} = Map.take(group, [:id])
      %{id: parent_id} = insert(:domain, domain_group: group)

      %{name: name, description: description, external_id: external_id, parent_id: ^parent_id} =
        params =
        build(:domain, parent_id: parent_id)
        |> Map.take([:name, :description, :external_id, :parent_id])

      assert {:ok, domain} = Taxonomies.create_domain(params)

      assert %Domain{
               parent_id: ^parent_id,
               name: ^name,
               description: ^description,
               external_id: ^external_id,
               domain_group_id: ^domain_group_id
             } = domain
    end

    test "create_domain/1 will create the group if provided and does not exist" do
      group = insert(:domain_group)
      %{id: parent_id} = insert(:domain, domain_group: group)

      %{
        name: name,
        description: description,
        external_id: external_id,
        parent_id: ^parent_id,
        domain_group: group
      } =
        params =
        build(:domain, parent_id: parent_id)
        |> Map.put(:domain_group, "foo")
        |> Map.take([:name, :description, :external_id, :parent_id, :domain_group])

      assert {:ok, domain} = Taxonomies.create_domain(params)
      assert %{id: domain_group_id} = Groups.get_by(name: group)

      assert %Domain{
               parent_id: ^parent_id,
               name: ^name,
               description: ^description,
               external_id: ^external_id,
               domain_group_id: ^domain_group_id
             } = domain
    end

    test "create_domain/1 take the provided group if exists" do
      group = insert(:domain_group)
      %{id: parent_id} = insert(:domain)

      %{
        name: name,
        description: description,
        external_id: external_id,
        parent_id: ^parent_id,
        domain_group: domain_group
      } =
        params =
        build(:domain, parent_id: parent_id)
        |> Map.put(:domain_group, group.name)
        |> Map.take([:name, :description, :external_id, :parent_id, :domain_group])

      assert {:ok, domain} = Taxonomies.create_domain(params)
      assert %{id: domain_group_id} = Groups.get_by(name: domain_group)

      assert %Domain{
               parent_id: ^parent_id,
               name: ^name,
               description: ^description,
               external_id: ^external_id,
               domain_group_id: ^domain_group_id
             } = domain
    end

    test "create_domain/1 with an existing name should return an error" do
      %{name: name} = insert(:domain)

      assert {:error, changeset} =
               Taxonomies.create_domain(%{
                 name: name,
                 external_id: "External id: #{:rand.uniform(100_000_000)}"
               })

      assert %{errors: [name: error], valid?: false} = changeset
      assert {"has already been taken", [constraint: :unique, constraint_name: _]} = error
    end

    test "create_domain/1 with an existing external_id should return an error" do
      %{external_id: external_id} = insert(:domain)

      assert {:error, changeset} =
               Taxonomies.create_domain(%{name: "new name", external_id: external_id})

      assert %{errors: [external_id: error], valid?: false} = changeset
      assert {"has already been taken", [constraint: :unique, constraint_name: _]} = error
    end

    test "create_domain/1 with no external_id should return an error" do
      assert {:error, changeset} = Taxonomies.create_domain(%{name: "new name"})

      assert %{errors: [external_id: error], valid?: false} = changeset
      assert {"can't be blank", [validation: :required]} = error
    end

    test "create_domain/1 with an existing name in a deleted domain should create the domain" do
      %{name: name} = domain_to_delete = insert(:domain)
      assert {:ok, %Domain{}} = Taxonomies.delete_domain(domain_to_delete)

      assert {:ok, %Domain{name: ^name}} =
               Taxonomies.create_domain(%{
                 name: name,
                 external_id: "External id: #{:rand.uniform(100_000_000)}"
               })
    end

    test "create_domain/1 with an existing external_id in a deleted domain should create the domain" do
      %{external_id: external_id} = domain_to_delete = insert(:domain)
      assert {:ok, %Domain{}} = Taxonomies.delete_domain(domain_to_delete)

      assert {:ok, %Domain{external_id: ^external_id}} =
               Taxonomies.create_domain(%{name: "new name", external_id: external_id})
    end

    test "create_domain/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Taxonomies.create_domain(%{})
    end

    test "update_domain/2 with valid data updates the domain" do
      domain = insert(:domain)

      %{name: name, description: description, external_id: external_id} =
        params = build(:domain) |> Map.take([:name, :description, :external_id])

      assert {:ok, domain} = Taxonomies.update_domain(domain, params)
      assert %Domain{name: ^name, external_id: ^external_id, description: ^description} = domain
    end

    test "update_domain/2 with invalid data returns error changeset" do
      domain = insert(:domain)
      assert {:error, %Ecto.Changeset{}} = Taxonomies.update_domain(domain, %{"name" => nil})
    end

    test "update_domain/2 with an existing domain name should return an error" do
      %{name: name} = insert(:domain)
      domain = insert(:domain)

      assert {:error, changeset} = Taxonomies.update_domain(domain, %{name: name})
      assert %{errors: [name: error], valid?: false} = changeset
      assert {"has already been taken", [constraint: :unique, constraint_name: _]} = error
    end

    test "update_domain/2 with an existing name on same group should return an error" do
      group = insert(:domain_group)
      %{name: name} = insert(:domain, domain_group: group)
      domain = insert(:domain)

      assert {:error, changeset} =
               Taxonomies.update_domain(domain, %{name: name, domain_group_id: group.id})

      assert %{errors: [name: error], valid?: false} = changeset
      assert {"has already been taken", [constraint: :unique, constraint_name: _]} = error
    end

    test "update_domain/2 with an existing name on different group" do
      group = insert(:domain_group)
      %{name: name} = insert(:domain, domain_group: group)
      domain = insert(:domain)
      group = insert(:domain_group)

      assert {:ok, %Domain{name: ^name}} =
               Taxonomies.update_domain(domain, %{name: name, domain_group_id: group.id})
    end

    test "update_domain/2 with an existing external_id should return an error" do
      %{external_id: external_id} = insert(:domain)
      domain = insert(:domain)

      assert {:error, changeset} = Taxonomies.update_domain(domain, %{external_id: external_id})
      assert %{errors: [external_id: error], valid?: false} = changeset
      assert {"has already been taken", [constraint: :unique, constraint_name: _]} = error
    end

    test "update_domain/2 with an existing domain name should be updated when the domain is deleted" do
      %{name: name} = domain_to_delete = insert(:domain)
      domain_to_update = insert(:domain)

      assert {:ok, %Domain{}} = Taxonomies.delete_domain(domain_to_delete)

      assert {:ok, %Domain{name: ^name}} =
               Taxonomies.update_domain(domain_to_update, %{name: name})
    end

    test "update_domain/2 updates the domain group and its children's when its informed and they are linked to some group" do
      group_name = "foo"
      root_group = insert(:domain_group)
      root_children_group = insert(:domain_group)
      root = insert(:domain, id: 0, domain_group: root_group)

      root_children =
        Enum.map(1..5, fn level ->
          insert(:domain, id: level, parent_id: level - 1, domain_group: root_group)
        end)

      children =
        Enum.map(6..10, fn level ->
          insert(:domain, id: level, parent_id: level - 1, domain_group: root_children_group)
        end)

      assert {:ok, %Domain{domain_group: %{name: ^group_name}}} =
               Taxonomies.update_domain(root, %{domain_group: group_name})

      assert %{id: domain_group_id} = Groups.get_by(name: group_name)

      assert Enum.all?(
               root_children,
               &(Taxonomies.get_domain!(&1.id).domain_group_id == domain_group_id)
             )

      assert %{id: domain_group_id} = Groups.get_by(name: root_children_group.name)

      assert Enum.all?(
               children,
               &(Taxonomies.get_domain!(&1.id).domain_group_id == domain_group_id)
             )
    end

    test "update_domain/2 updates the domain group and its children's when its informed and they are not linked to some group" do
      group_name = "foo"
      root_children_group = insert(:domain_group)
      root = insert(:domain, id: 0)

      root_children =
        Enum.map(1..5, fn level -> insert(:domain, id: level, parent_id: level - 1) end)

      children =
        Enum.map(6..10, fn level ->
          insert(:domain, id: level, parent_id: level - 1, domain_group: root_children_group)
        end)

      assert {:ok, %Domain{domain_group: %{name: ^group_name}}} =
               Taxonomies.update_domain(root, %{domain_group: group_name})

      assert %{id: domain_group_id} = Groups.get_by(name: group_name)

      assert Enum.all?(
               root_children,
               &(Taxonomies.get_domain!(&1.id).domain_group_id == domain_group_id)
             )

      assert %{id: domain_group_id} = Groups.get_by(name: root_children_group.name)

      assert Enum.all?(
               children,
               &(Taxonomies.get_domain!(&1.id).domain_group_id == domain_group_id)
             )
    end

    test "update_domain/2 deletes the group when specified" do
      root_group = insert(:domain_group)
      root_children_group = insert(:domain_group)
      root = insert(:domain, id: 0, domain_group: root_group)

      root_children =
        Enum.map(1..5, fn level ->
          insert(:domain, id: level, parent_id: level - 1, domain_group: root_group)
        end)

      children =
        Enum.map(6..10, fn level ->
          insert(:domain, id: level, parent_id: level - 1, domain_group: root_children_group)
        end)

      assert {:ok, %Domain{domain_group: nil}} =
               Taxonomies.update_domain(root, %{domain_group: nil})

      assert %{id: _domain_group_id} = Groups.get_by(name: root_group.name)

      assert Enum.all?(
               root_children,
               &is_nil(Taxonomies.get_domain!(&1.id).domain_group_id)
             )

      assert %{id: domain_group_id} = Groups.get_by(name: root_children_group.name)

      assert Enum.all?(
               children,
               &(Taxonomies.get_domain!(&1.id).domain_group_id == domain_group_id)
             )
    end

    test "update_domain/2 inherits parent group on deletion" do
      root_group = insert(:domain_group)
      root_children_group = insert(:domain_group)
      insert(:domain, id: 0, domain_group: root_group)

      root_children =
        Enum.map(1..5, fn level ->
          insert(:domain, id: level, parent_id: level - 1, domain_group: root_group)
        end)

      root = insert(:domain, id: 6, domain_group: root_children_group, parent_id: 5)

      children =
        Enum.map(7..10, fn level ->
          insert(:domain, id: level, parent_id: level - 1, domain_group: root_children_group)
        end)

      assert %{id: domain_group_id} = Groups.get_by(name: root_group.name)

      assert {:ok, %Domain{domain_group_id: ^domain_group_id}} =
               Taxonomies.update_domain(root, %{domain_group: nil})

      assert Enum.all?(
               root_children ++ children,
               &(Taxonomies.get_domain!(&1.id).domain_group_id == domain_group_id)
             )
    end

    test "update_domain/2 fails when moving domain to group having domains with the same name" do
      group = insert(:domain_group)
      insert(:domain, domain_group: group, name: "name")
      d2 = insert(:domain, name: "name1")
      d3 = insert(:domain, name: "name", parent_id: d2.id)

      assert {:error, changeset} = Taxonomies.update_domain(d2, %{domain_group: group.name})
      assert %{errors: [name: error], valid?: false} = changeset
      assert {"has already been taken", [constraint: :unique, constraint_name: _]} = error
      assert is_nil(d2.domain_group_id)
      assert is_nil(d3.domain_group_id)
    end

    test "update_domain/2 changes parent and updates children group from it" do
      group = insert(:domain_group)
      to_change = insert(:domain_group)
      parent = insert(:domain, domain_group: group, name: "parent")
      child = insert(:domain, domain_group: group, name: "child", parent_id: parent.id)

      d2 = insert(:domain, name: "name1", domain_group: to_change)
      d3 = insert(:domain, name: "name2", parent_id: d2.id, domain_group: to_change)
      d4 = insert(:domain, name: "name3", parent_id: d3.id, domain_group: to_change)

      assert {:ok, %Domain{parent_id: parent_id, domain_group_id: domain_group_id}} =
               Taxonomies.update_domain(d3, %{parent_id: child.id})

      assert domain_group_id == group.id
      assert parent_id == child.id

      assert %Domain{parent_id: parent_id, domain_group_id: domain_group_id} =
               Taxonomies.get_domain!(d4.id)

      assert domain_group_id == group.id
      assert parent_id == d3.id
    end

    test "update_domain/2 changes parent and leaves children groups unchanged when they are their own group" do
      group = insert(:domain_group)
      group1 = insert(:domain_group)

      parent = insert(:domain, domain_group: group, name: "parent")
      child = insert(:domain, domain_group: group, name: "child", parent_id: parent.id)

      d2 = insert(:domain, name: "name1", domain_group: group1)
      d3 = insert(:domain, name: "name2")
      d4 = insert(:domain, name: "name3", parent_id: d3.id, domain_group: group1)
      d5 = insert(:domain, name: "name4", parent_id: d4.id, domain_group: group1)

      assert {:ok, %Domain{parent_id: parent_id, domain_group_id: domain_group_id}} =
               Taxonomies.update_domain(d2, %{parent_id: child.id})

      assert domain_group_id == group1.id
      assert parent_id == child.id

      assert {:ok, %Domain{parent_id: parent_id, domain_group_id: domain_group_id}} =
               Taxonomies.update_domain(d4, %{parent_id: child.id})

      assert domain_group_id == group1.id
      assert parent_id == child.id

      assert %Domain{parent_id: parent_id, domain_group_id: domain_group_id} =
               Taxonomies.get_domain!(d5.id)

      assert domain_group_id == group1.id
      assert parent_id == d4.id
    end

    test "update_domain/2 when updates parent and group at the same time group prevails" do
      group = insert(:domain_group)
      group1 = insert(:domain_group)

      parent = insert(:domain, domain_group: group, name: "parent")
      child = insert(:domain, domain_group: group, name: "child", parent_id: parent.id)

      d1 = insert(:domain, name: "name1")
      d2 = insert(:domain, name: "name2", parent_id: d1.id)

      assert {:ok, %Domain{}} =
               Taxonomies.update_domain(d2, %{parent_id: child.id, domain_group: group1.name})
    end

    test "update_domain/2 when updates parent without group and existing business concept fails" do
      group = insert(:domain_group)

      parent = insert(:domain, name: "parent")
      child = insert(:domain, name: "child", parent_id: parent.id)
      concept = insert(:business_concept, domain: child)
      insert(:business_concept_version, name: "name", business_concept: concept)

      d1 = insert(:domain, name: "name1", domain_group: group)
      d2 = insert(:domain, name: "name2", parent_id: d1.id, domain_group: group)
      concept = insert(:business_concept, domain: d2)
      insert(:business_concept_version, name: "name", business_concept: concept)

      assert {:error, changeset} = Taxonomies.update_domain(d2, %{parent_id: parent.id})
      assert %{errors: [business_concept: error], valid?: false} = changeset
      assert {"domain.error.existing.business_concept.name", []} = error
    end

    test "update_domain/2 when updates group with an existing business concept fails" do
      group = insert(:domain_group)
      group1 = insert(:domain_group)

      parent = insert(:domain, name: "parent", domain_group: group)
      child1 = insert(:domain, name: "child1", domain_group: group, parent_id: parent.id)
      concept = insert(:business_concept, domain: child1)
      insert(:business_concept_version, name: "name", business_concept: concept)

      child2 = insert(:domain, name: "child2", domain_group: group1, parent_id: parent.id)
      concept = insert(:business_concept, domain: child2)
      insert(:business_concept_version, name: "name", business_concept: concept)

      assert {:error, changeset} = Taxonomies.update_domain(child2, %{domain_group: group.name})
      assert %{errors: [business_concept: error], valid?: false} = changeset
      assert {"domain.error.existing.business_concept.name", []} = error
    end

    test "update_domain/2 updates group with an inactive business concept" do
      group = insert(:domain_group)
      group1 = insert(:domain_group)
      group_id = Map.get(group, :id)

      parent = insert(:domain, name: "parent", domain_group: group)
      child1 = insert(:domain, name: "child1", domain_group: group, parent_id: parent.id)
      concept = insert(:business_concept, domain: child1)

      insert(:business_concept_version,
        name: "name",
        business_concept: concept,
        status: "versioned"
      )

      child2 = insert(:domain, name: "child2", domain_group: group1, parent_id: parent.id)
      concept = insert(:business_concept, domain: child2)
      insert(:business_concept_version, name: "name", business_concept: concept)

      assert {:ok, %Domain{domain_group_id: ^group_id}} =
               Taxonomies.update_domain(child2, %{domain_group: group.name})
    end

    test "update_domain/2 updates group with different business concepts" do
      group = insert(:domain_group)
      group1 = insert(:domain_group)
      group_id = Map.get(group, :id)

      parent = insert(:domain, name: "parent", domain_group: group)
      child1 = insert(:domain, name: "child1", domain_group: group, parent_id: parent.id)
      concept = insert(:business_concept, domain: child1)
      insert(:business_concept_version, name: "name", business_concept: concept)

      child2 = insert(:domain, name: "child2", domain_group: group1, parent_id: parent.id)
      concept = insert(:business_concept, domain: child2)
      insert(:business_concept_version, name: "name1", business_concept: concept)

      assert {:ok, %Domain{domain_group_id: ^group_id}} =
               Taxonomies.update_domain(child2, %{domain_group: group.name})
    end

    test "update_domain/2 updates group with same business concepts with different type" do
      group = insert(:domain_group)
      group1 = insert(:domain_group)
      group_id = Map.get(group, :id)

      domain = insert(:domain, name: "domain", domain_group: group)
      concept = insert(:business_concept, domain: domain, type: "type")
      insert(:business_concept_version, name: "name", business_concept: concept)

      domain = insert(:domain, name: "domain1", domain_group: group1, type: "type1")
      concept = insert(:business_concept, domain: domain)
      insert(:business_concept_version, name: "name", business_concept: concept)

      assert {:ok, %Domain{domain_group_id: ^group_id}} =
               Taxonomies.update_domain(domain, %{domain_group: group.name})
    end

    test "update_domain/2 manage only direct descendents" do
      g1 = insert(:domain_group)
      g2 = insert(:domain_group)
      root = insert(:domain, id: 0, domain_group: g1)

      root_children =
        Enum.map(1..5, fn level ->
          insert(:domain, id: level, parent_id: level - 1, domain_group: g1)
        end)

      insert(:domain, id: 6, domain_group: g2, parent_id: 5)

      children =
        Enum.map(7..10, fn level ->
          insert(:domain, id: level, parent_id: level - 1, domain_group: g1)
        end)

      assert %{id: domain_group_id} = Groups.get_by(name: g1.name)

      assert {:ok, %Domain{domain_group_id: nil}} =
               Taxonomies.update_domain(root, %{domain_group: nil})

      assert Enum.all?(
               root_children,
               &is_nil(Taxonomies.get_domain!(&1.id).domain_group_id)
             )

      assert Enum.all?(
               children,
               &(Taxonomies.get_domain!(&1.id).domain_group_id == domain_group_id)
             )
    end

    test "update_domain/2 does not change domain group from parent if child and parent have the same group" do
      g = insert(:domain_group)
      d1 = insert(:domain, domain_group: g)
      d2 = insert(:domain, domain_group: g)

      insert(:business_concept_version,
        name: "name",
        business_concept: insert(:business_concept, domain: d1)
      )

      insert(:business_concept_version,
        name: "name1",
        business_concept: insert(:business_concept, domain: d2)
      )

      domain_group_id = g.id

      assert {:ok, %Domain{domain_group_id: ^domain_group_id}} =
               Taxonomies.update_domain(d2, %{parent_id: d1.id})
    end

    test "delete_domain/1 soft-deletes the domain" do
      domain = insert(:domain)
      assert {:ok, %Domain{}} = Taxonomies.delete_domain(domain)
      assert %{deleted_at: deleted_at} = Repo.get(Domain, domain.id)
      assert deleted_at
    end

    test "delete_domain/1 with existing deprecated business concepts is deleted" do
      domain = insert(:domain)
      business_concept_1 = insert(:business_concept, domain: domain)
      business_concept_2 = insert(:business_concept, domain: domain)

      insert(:business_concept_version, status: "deprecated", business_concept: business_concept_1)

      insert(:business_concept_version, status: "deprecated", business_concept: business_concept_2)

      assert {:ok, %Domain{}} = Taxonomies.delete_domain(domain)
      assert %{deleted_at: deleted_at} = Repo.get(Domain, domain.id)
      assert deleted_at
    end

    test "delete_domain/1 with existing deprecated and draft business concepts can not be deleted" do
      domain = insert(:domain)
      business_concept_1 = insert(:business_concept, domain: domain)
      business_concept_2 = insert(:business_concept, domain: domain)
      business_concept_3 = insert(:business_concept, domain: domain)

      insert(:business_concept_version, status: "deprecated", business_concept: business_concept_1)

      insert(:business_concept_version, status: "draft", business_concept: business_concept_2)
      insert(:business_concept_version, status: "draft", business_concept: business_concept_3)

      assert {:error, %Ecto.Changeset{} = changeset} = Taxonomies.delete_domain(domain)
      [{:domain, {error_message, code}} | _] = changeset.errors
      [{:code, id} | _] = code
      assert !changeset.valid?
      assert error_message == "existing.business.concept"
      assert id == "ETD002"
    end

    test "delete_domain/1 with existing child domains can not be deleted" do
      %{parent: parent_domain} = _child_domain = insert(:domain, parent: build(:domain))

      assert {:error, changeset} = Taxonomies.delete_domain(parent_domain)
      assert %{errors: errors, valid?: false} = changeset
      assert [domain: {"existing.domain", [code: "ETD001"]}] = errors
    end

    test "delete_domain/1 deletes the domain an create the same domain" do
      params = build(:domain) |> Map.take([:name, :description, :external_id])

      assert {:ok, %Domain{} = domain} = Taxonomies.create_domain(params)
      assert {:ok, %Domain{}} = Taxonomies.delete_domain(domain)
      assert {:error, :not_found} = Taxonomies.get_domain(domain.id)
      assert {:ok, %Domain{}} = Taxonomies.create_domain(params)
    end

    test "count/1 returns child count for a domain" do
      %{id: id} = insert(:domain)
      insert(:domain, parent_id: id)
      insert(:domain, parent_id: id)
      insert(:domain, parent_id: id, deleted_at: DateTime.utc_now())

      assert Taxonomies.count(parent_id: id, deleted_at: nil) == 2
    end

    test "apply_changes/2 returns a new Domain with changes applied" do
      domain = build(:domain)
      params = Map.take(domain, [:name, :external_id, :description])
      assert Taxonomies.apply_changes(Domain, params) == domain
    end

    test "apply_changes/2 returns an existing Domain with changes applied" do
      %{id: id, name: name, external_id: external_id} = domain = insert(:domain)
      %{id: parent_id} = insert(:domain)

      assert %{parent_id: ^parent_id, id: ^id, name: ^name, external_id: ^external_id} =
               Taxonomies.apply_changes(domain, %{"parent_id" => parent_id})
    end

    test "get_parentable_ids/2 returns the ids of possible parent domains" do
      deleted_ids =
        1..5
        |> Enum.map(fn _ -> insert(:domain, deleted_at: DateTime.utc_now()) end)
        |> Enum.map(& &1.id)
        |> MapSet.new()

      parent_ids =
        1..5
        |> Enum.map(fn _ -> insert(:domain) end)
        |> Enum.map(& &1.id)
        |> MapSet.new()

      %{id: domain_id} = domain = insert(:domain, parent_id: Enum.random(parent_ids))

      child_ids =
        1..5
        |> Enum.map(fn _ -> insert(:domain, parent_id: domain_id) end)
        |> Enum.map(& &1.id)
        |> MapSet.new()

      claims = build(:claims, role: "admin")

      parentable_ids = claims |> Taxonomies.get_parentable_ids(domain) |> MapSet.new()

      assert MapSet.equal?(parentable_ids, parent_ids)
      refute MapSet.member?(parentable_ids, domain_id)
      assert MapSet.disjoint?(parentable_ids, child_ids)
      assert MapSet.disjoint?(parentable_ids, deleted_ids)
    end
  end
end
