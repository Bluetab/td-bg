defmodule TdBg.Taxonomies.DomainTest do
  use TdBg.DataCase

  alias Ecto.Changeset
  alias TdBg.Repo
  alias TdBg.Taxonomies.Domain

  describe "changeset/2" do
    test "validates required fields" do
      assert %{errors: [name: error]} = Domain.changeset(%{})
      assert {_msg, [validation: :required]} = error
    end

    test "validates unique constraint on name" do
      insert(:domain, name: "foo")

      assert {:error, changeset} = %{name: "foo"} |> Domain.changeset() |> Repo.insert()
      assert %{errors: [name: error]} = changeset
      assert {_msg, [constraint: :unique, constraint_name: "domains_name_index"]} = error
    end

    test "validates unique constraint on external_id" do
      insert(:domain, external_id: "foo")

      assert {:error, changeset} =
               %{external_id: "foo", name: "foo"} |> Domain.changeset() |> Repo.insert()

      assert %{errors: [external_id: error]} = changeset
      assert {_msg, [constraint: :unique, constraint_name: "domains_external_id_index"]} = error
    end

    test "validates parent_id is not a descendent" do
      %{id: child_id, parent: parent} = insert(:domain, parent: build(:domain))

      assert {:error, changeset} =
               parent |> Domain.changeset(%{parent_id: child_id}) |> Repo.update()

      assert %{errors: [parent_id: error]} = changeset
      assert {_msg, [validation: :exclusion, enum: _descendent_ids]} = error
    end

    test "validates parent_id is not self" do
      %{id: id} = domain = insert(:domain)

      assert {:error, changeset} = domain |> Domain.changeset(%{parent_id: id}) |> Repo.update()

      assert %{errors: [parent_id: error]} = changeset
      assert {_msg, [validation: :exclusion, enum: _descendent_ids]} = error
    end

    test "discards deleted_at" do
      params = %{"deleted_at" => "2018-11-14 09:31:07Z", "name" => "foo"}
      refute params |> Domain.changeset() |> Changeset.get_change(:deleted_at)
    end
  end
end
