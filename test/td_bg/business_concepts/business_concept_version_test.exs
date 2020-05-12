defmodule TdBg.BusinessConcepts.BusinessConceptVersionTest do
  use TdBg.DataCase

  alias Ecto.Changeset
  alias TdBg.BusinessConcepts.BusinessConceptVersion

  @create_attrs %{
    content: %{},
    name: "some name",
    last_change_by: 1,
    last_change_at: DateTime.utc_now(),
    version: 1,
    business_concept: %{id: 1},
    in_progress: true
  }

  describe "TdBg.BusinessConcepts.BusinessConceptVersion" do
    test "create_changeset/2 trims name" do
      attrs = Map.put(@create_attrs, :name, "  foo  ")
      changeset = BusinessConceptVersion.create_changeset(%BusinessConceptVersion{}, attrs)
      assert changeset.valid?
      assert Changeset.get_change(changeset, :name) == "foo"
    end

    test "update_changeset/2 trims name" do
      bcv = insert(:business_concept_version)
      attrs = %{name: "   foo   "}
      changeset = BusinessConceptVersion.update_changeset(bcv, attrs)
      assert changeset.valid?
      assert Changeset.get_change(changeset, :name) == "foo"
    end

    test "update_changeset/2 sets status to draft" do
      bcv = insert(:business_concept_version, status: "published")
      attrs = %{name: "foo"}
      changeset = BusinessConceptVersion.update_changeset(bcv, attrs)
      assert changeset.valid?
      assert Changeset.get_change(changeset, :status) == "draft"
    end

    test "bulk_update_changeset/2 trims name" do
      bcv = insert(:business_concept_version)
      attrs = %{name: "   foo   "}
      changeset = BusinessConceptVersion.bulk_update_changeset(bcv, attrs)
      assert changeset.valid?
      assert Changeset.get_change(changeset, :name) == "foo"
    end

    test "bulk_update_changeset/2 does not change status" do
      bcv = insert(:business_concept_version, status: "published")
      attrs = %{name: "foo"}
      changeset = BusinessConceptVersion.bulk_update_changeset(bcv, attrs)
      assert changeset.valid?
      refute Changeset.get_change(changeset, :status)
    end
  end
end
