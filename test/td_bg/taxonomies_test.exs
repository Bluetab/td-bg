defmodule TdBg.TaxonomiesTest do
  use TdBg.DataCase

  alias TdBg.Groups
  alias TdBg.Repo
  alias TdBg.Taxonomies
  alias TdBg.Taxonomies.Domain

  setup_all do
    start_supervised(TdBg.Cache.DomainLoader)
    :ok
  end

  describe "list_domains/1" do
    setup do
      [
        domain: insert(:domain, domain_group: build(:domain_group)),
        deleted_domain: insert(:domain, deleted_at: DateTime.utc_now())
      ]
    end

    test "returns non-deleted domains", %{domain: %{id: id}} do
      assert [%{id: ^id}] = Taxonomies.list_domains()
    end

    test "returns deleted domains", %{deleted_domain: %{id: id}} do
      assert [%{id: ^id}] = Taxonomies.list_domains(%{}, deleted: true)
    end

    test "preloads associations", %{domain: %{id: id, domain_group_id: group_id}} do
      assert [%{id: ^id, domain_group: %{id: ^group_id}}] =
               Taxonomies.list_domains(%{}, preload: [:domain_group])
    end

    test "returns domains filtered by ids", %{domain: %{id: domain_id1}} do
      %{id: domain_id2} = insert(:domain)

      assert [%{id: ^domain_id1}, %{id: ^domain_id2}] =
               Taxonomies.list_domains(%{domain_ids: [domain_id1, domain_id2]})

      assert [%{id: ^domain_id1}] = Taxonomies.list_domains(%{domain_ids: [domain_id1]})

      assert [%{id: ^domain_id2}] = Taxonomies.list_domains(%{domain_ids: [domain_id2]})

      assert [] = Taxonomies.list_domains(%{domain_ids: []})
    end
  end

  describe "get_domain!/1" do
    test "get_domain!/1 returns the domain with given id" do
      %{id: id} = domain = insert(:domain)
      assert Taxonomies.get_domain!(id) == domain
    end
  end

  describe "get_children_domains/1" do
    test "returns the children domain of a domain" do
      parent = insert(:domain)

      children = Enum.map(0..2, fn _ -> insert(:domain, parent: parent) end)

      domains =
        parent
        |> Taxonomies.get_children_domains()
        |> Enum.sort_by(& &1.id)

      assert Enum.map(domains, & &1.id) == Enum.map(children, & &1.id)
    end
  end

  describe "create_domain/1" do
    test "with valid data creates a domain" do
      %{name: name, description: description, external_id: external_id} =
        params =
        build(:domain)
        |> Map.take([:name, :description, :external_id])

      assert {:ok, domain} = Taxonomies.create_domain(params)
      assert %Domain{name: ^name, description: ^description, external_id: ^external_id} = domain
    end

    test "child of a parent domain" do
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

    test "child of a parent domain will inherit its parent group" do
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

    test "will create the group if provided and does not exist" do
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

    test "take the provided group if exists" do
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

    test "with an existing name should return an error" do
      %{name: name} = insert(:domain)

      assert {:error, changeset} =
               Taxonomies.create_domain(%{
                 name: name,
                 external_id: "External id: #{System.unique_integer([:positive])}"
               })

      assert %{errors: [name: error], valid?: false} = changeset
      assert {"has already been taken", [constraint: :unique, constraint_name: _]} = error
    end

    test "with an existing external_id should return an error" do
      %{external_id: external_id} = insert(:domain)

      assert {:error, changeset} =
               Taxonomies.create_domain(%{name: "new name", external_id: external_id})

      assert %{errors: [external_id: error], valid?: false} = changeset
      assert {"has already been taken", [constraint: :unique, constraint_name: _]} = error
    end

    test "with no external_id should return an error" do
      assert {:error, changeset} = Taxonomies.create_domain(%{name: "new name"})

      assert %{errors: [external_id: error], valid?: false} = changeset
      assert {"can't be blank", [validation: :required]} = error
    end

    test "with an existing name in a deleted domain should create the domain" do
      %{name: name} = domain_to_delete = insert(:domain)
      assert {:ok, %Domain{}} = Taxonomies.delete_domain(domain_to_delete)

      assert {:ok, %Domain{name: ^name}} =
               Taxonomies.create_domain(%{
                 name: name,
                 external_id: "External id: #{System.unique_integer([:positive])}"
               })
    end

    test "with an existing external_id in a deleted domain should create the domain" do
      %{external_id: external_id} = domain_to_delete = insert(:domain)
      assert {:ok, %Domain{}} = Taxonomies.delete_domain(domain_to_delete)

      assert {:ok, %Domain{external_id: ^external_id}} =
               Taxonomies.create_domain(%{name: "new name", external_id: external_id})
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Taxonomies.create_domain(%{})
    end
  end

  describe "update_domain/2" do
    test "with valid data updates the domain" do
      domain = insert(:domain)

      %{name: name, description: description, external_id: external_id} =
        params = build(:domain) |> Map.take([:name, :description, :external_id])

      assert {:ok, domain} = Taxonomies.update_domain(domain, params)
      assert %Domain{name: ^name, external_id: ^external_id, description: ^description} = domain
    end

    test "with invalid data returns error changeset" do
      domain = insert(:domain)
      assert {:error, %Ecto.Changeset{}} = Taxonomies.update_domain(domain, %{"name" => nil})
    end

    test "with an existing domain name should return an error" do
      %{name: name} = insert(:domain)
      domain = insert(:domain)

      assert {:error, changeset} = Taxonomies.update_domain(domain, %{name: name})
      assert %{errors: [name: error], valid?: false} = changeset
      assert {"has already been taken", [constraint: :unique, constraint_name: _]} = error
    end

    test "with an existing name on same group should return an error" do
      group = insert(:domain_group)
      %{name: name} = insert(:domain, domain_group: group)
      domain = insert(:domain)

      assert {:error, changeset} =
               Taxonomies.update_domain(domain, %{name: name, domain_group_id: group.id})

      assert %{errors: [name: error], valid?: false} = changeset
      assert {"has already been taken", [constraint: :unique, constraint_name: _]} = error
    end

    test "with an existing name on different group" do
      group = insert(:domain_group)
      %{name: name} = insert(:domain, domain_group: group)
      domain = insert(:domain)
      group = insert(:domain_group)

      assert {:ok, %Domain{name: ^name}} =
               Taxonomies.update_domain(domain, %{name: name, domain_group_id: group.id})
    end

    test "with an existing external_id should return an error" do
      %{external_id: external_id} = insert(:domain)
      domain = insert(:domain)

      assert {:error, changeset} = Taxonomies.update_domain(domain, %{external_id: external_id})
      assert %{errors: [external_id: error], valid?: false} = changeset
      assert {"has already been taken", [constraint: :unique, constraint_name: _]} = error
    end

    test "with an existing domain name should be updated when the domain is deleted" do
      %{name: name} = domain_to_delete = insert(:domain)
      domain_to_update = insert(:domain)

      assert {:ok, %Domain{}} = Taxonomies.delete_domain(domain_to_delete)

      assert {:ok, %Domain{name: ^name}} =
               Taxonomies.update_domain(domain_to_update, %{name: name})
    end

    test "updates the domain group and its children's when its informed and they are linked to some group" do
      group_name = "foo"
      root_group = insert(:domain_group)
      root_children_group = insert(:domain_group)
      root = insert(:domain, id: 1, domain_group: root_group)

      root_children =
        Enum.map(2..6, fn level ->
          insert(:domain, id: level, parent_id: level - 1, domain_group: root_group)
        end)

      children =
        Enum.map(7..11, fn level ->
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

    test "updates the domain group and its children's when its informed and they are not linked to some group" do
      group_name = "foo"
      root_children_group = insert(:domain_group)
      root = insert(:domain, id: 1)

      root_children =
        Enum.map(2..6, fn level -> insert(:domain, id: level, parent_id: level - 1) end)

      children =
        Enum.map(7..11, fn level ->
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

    test "deletes the group when specified" do
      root_group = insert(:domain_group)
      root_children_group = insert(:domain_group)
      root = insert(:domain, id: 1, domain_group: root_group)

      root_children =
        Enum.map(2..6, fn level ->
          insert(:domain, id: level, parent_id: level - 1, domain_group: root_group)
        end)

      children =
        Enum.map(7..11, fn level ->
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

    test "inherits parent group on deletion" do
      root_group = insert(:domain_group)
      root_children_group = insert(:domain_group)
      insert(:domain, id: 1, domain_group: root_group)

      root_children =
        Enum.map(2..6, fn level ->
          insert(:domain, id: level, parent_id: level - 1, domain_group: root_group)
        end)

      root = insert(:domain, id: 7, domain_group: root_children_group, parent_id: 5)

      children =
        Enum.map(8..11, fn level ->
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

    test "fails when moving domain to group having domains with the same name" do
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

    test "changes parent and updates children group from it" do
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

    test "changes parent and leaves children groups unchanged when they are their own group" do
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

    test "when updates parent and group at the same time group prevails" do
      group = insert(:domain_group)
      group1 = insert(:domain_group)

      parent = insert(:domain, domain_group: group, name: "parent")
      child = insert(:domain, domain_group: group, name: "child", parent_id: parent.id)

      d1 = insert(:domain, name: "name1")
      d2 = insert(:domain, name: "name2", parent_id: d1.id)

      assert {:ok, %Domain{}} =
               Taxonomies.update_domain(d2, %{parent_id: child.id, domain_group: group1.name})
    end

    test "when updates parent without group and existing business concept fails" do
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

    test "when updates group with an existing business concept fails" do
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

    test "updates group with an inactive business concept" do
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

    test "updates group with different business concepts" do
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

    test "updates group with same business concepts with different type" do
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

    test "manage only direct descendents" do
      g1 = insert(:domain_group)
      g2 = insert(:domain_group)
      root = insert(:domain, id: 1, domain_group: g1)

      root_children =
        Enum.map(2..6, fn level ->
          insert(:domain, id: level, parent_id: level - 1, domain_group: g1)
        end)

      insert(:domain, id: 7, domain_group: g2, parent_id: 5)

      children =
        Enum.map(8..11, fn level ->
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

    test "does not change domain group from parent if child and parent have the same group" do
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
  end

  describe "delete_domain/1" do
    test "soft-deletes the domain" do
      domain = insert(:domain)
      assert {:ok, %Domain{}} = Taxonomies.delete_domain(domain)
      assert %{deleted_at: deleted_at} = Repo.get(Domain, domain.id)
      assert deleted_at
    end

    test "with existing deprecated business concepts is deleted" do
      domain = insert(:domain)
      business_concept_1 = insert(:business_concept, domain: domain)
      business_concept_2 = insert(:business_concept, domain: domain)

      insert(:business_concept_version, status: "deprecated", business_concept: business_concept_1)

      insert(:business_concept_version, status: "deprecated", business_concept: business_concept_2)

      assert {:ok, %Domain{}} = Taxonomies.delete_domain(domain)
      assert %{deleted_at: deleted_at} = Repo.get(Domain, domain.id)
      assert deleted_at
    end

    test "with existing deprecated and draft business concepts can not be deleted" do
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

    test "with existing child domains can not be deleted" do
      %{parent: parent_domain} = _child_domain = insert(:domain, parent: build(:domain))

      assert {:error, changeset} = Taxonomies.delete_domain(parent_domain)
      assert %{errors: errors, valid?: false} = changeset
      assert [domain: {"existing.domain", [code: "ETD001"]}] = errors
    end

    test "deletes the domain an create the same domain" do
      params = build(:domain) |> Map.take([:name, :description, :external_id])

      assert {:ok, %Domain{} = domain} = Taxonomies.create_domain(params)
      assert {:ok, %Domain{}} = Taxonomies.delete_domain(domain)
      assert {:error, :not_found} = Taxonomies.get_domain(domain.id)
      assert {:ok, %Domain{}} = Taxonomies.create_domain(params)
    end
  end

  describe "count/1" do
    test "returns child count for a domain" do
      %{id: id} = insert(:domain)
      insert(:domain, parent_id: id)
      insert(:domain, parent_id: id)
      insert(:domain, parent_id: id, deleted_at: DateTime.utc_now())

      assert Taxonomies.count(parent_id: id, deleted_at: nil) == 2
    end
  end

  describe "apply_changes/2" do
    test "returns a new Domain with changes applied" do
      domain = build(:domain)
      params = Map.take(domain, [:name, :external_id, :description])
      assert Taxonomies.apply_changes(Domain, params) == domain
    end

    test "returns an existing Domain with changes applied" do
      %{id: id, name: name, external_id: external_id} = domain = insert(:domain)
      %{id: parent_id} = insert(:domain)

      assert %{parent_id: ^parent_id, id: ^id, name: ^name, external_id: ^external_id} =
               Taxonomies.apply_changes(domain, %{"parent_id" => parent_id})
    end
  end

  describe "get_parentable_ids/2" do
    test "returns the ids of possible parent domains" do
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
