defmodule TdBg.TaxonomiesTest do
  use TdBg.DataCase

  alias TdBg.Cache.DomainLoader
  alias TdBg.Repo
  alias TdBg.Search.IndexWorker
  alias TdBg.Taxonomies

  setup_all do
    start_supervised(DomainLoader)
    start_supervised(IndexWorker)
    :ok
  end

  describe "domains" do
    alias TdBg.BusinessConcepts.BusinessConcept
    alias TdBg.Taxonomies.Domain

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

    test "create_domain/1 with an existing name should return an error" do
      %{name: name} = insert(:domain)
      assert {:error, changeset} = Taxonomies.create_domain(%{name: name})
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

    test "create_domain/1 with an existing name in a deleted domain should create the domain" do
      %{name: name} = domain_to_delete = insert(:domain)
      assert {:ok, %Domain{}} = Taxonomies.delete_domain(domain_to_delete)
      assert {:ok, %Domain{name: ^name} = domain} = Taxonomies.create_domain(%{name: name})
    end

    test "create_domain/1 with an existing external_id in a deleted domain should create the domain" do
      %{external_id: external_id} = domain_to_delete = insert(:domain)
      assert {:ok, %Domain{}} = Taxonomies.delete_domain(domain_to_delete)

      assert {:ok, %Domain{external_id: ^external_id} = domain} =
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

      insert(:business_concept_version,
        status: BusinessConcept.status().deprecated,
        business_concept: business_concept_1
      )

      insert(:business_concept_version,
        status: BusinessConcept.status().deprecated,
        business_concept: business_concept_2
      )

      assert {:ok, %Domain{}} = Taxonomies.delete_domain(domain)
      assert %{deleted_at: deleted_at} = Repo.get(Domain, domain.id)
      assert deleted_at
    end

    test "delete_domain/1 with existing deprecated and draft business concepts can not be deleted" do
      domain = insert(:domain)
      business_concept_1 = insert(:business_concept, domain: domain)
      business_concept_2 = insert(:business_concept, domain: domain)
      business_concept_3 = insert(:business_concept, domain: domain)

      insert(:business_concept_version,
        status: BusinessConcept.status().deprecated,
        business_concept: business_concept_1
      )

      insert(:business_concept_version,
        status: BusinessConcept.status().draft,
        business_concept: business_concept_2
      )

      insert(:business_concept_version,
        status: BusinessConcept.status().draft,
        business_concept: business_concept_3
      )

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

      user = build(:user, is_admin: true)

      parentable_ids = user |> Taxonomies.get_parentable_ids(domain) |> MapSet.new()

      assert MapSet.equal?(parentable_ids, parent_ids)
      refute MapSet.member?(parentable_ids, domain_id)
      assert MapSet.disjoint?(parentable_ids, child_ids)
      assert MapSet.disjoint?(parentable_ids, deleted_ids)
    end
  end
end
