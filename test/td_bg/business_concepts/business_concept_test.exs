defmodule TdBg.BusinessConcepts.BusinessConceptTest do
  use TdBg.DataCase

  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.Repo

  describe "TdBg.BusinessConcepts.BusinessConcept" do
    setup do
      %{id: domain_id} = insert(:domain)

      attrs = %{
        domain_id: domain_id,
        type: "foo",
        confidential: false,
        last_change_by: 0,
        last_change_at: DateTime.utc_now()
      }

      [attrs: attrs]
    end

    test "changeset/2 creates changeset", %{attrs: attrs} do
      %{
        confidential: confidential,
        domain_id: domain_id,
        last_change_by: last_change_by,
        last_change_at: last_change_at
      } = attrs

      assert %{
               valid?: true,
               changes: %{
                 confidential: ^confidential,
                 domain_id: ^domain_id,
                 last_change_by: ^last_change_by,
                 last_change_at: ^last_change_at
               }
             } = BusinessConcept.changeset(%BusinessConcept{}, attrs)
    end

    test "changeset/2 validates required fields", %{attrs: attrs} do
      assert %{valid?: false, errors: [domain_id: {"can't be blank", [validation: :required]}]} =
               BusinessConcept.changeset(%BusinessConcept{}, Map.delete(attrs, :domain_id))

      assert %{valid?: false, errors: [type: {"can't be blank", [validation: :required]}]} =
               BusinessConcept.changeset(%BusinessConcept{}, Map.delete(attrs, :type))

      assert %{
               valid?: false,
               errors: [last_change_by: {"can't be blank", [validation: :required]}]
             } = BusinessConcept.changeset(%BusinessConcept{}, Map.delete(attrs, :last_change_by))

      assert %{
               valid?: false,
               errors: [last_change_at: {"can't be blank", [validation: :required]}]
             } = BusinessConcept.changeset(%BusinessConcept{}, Map.delete(attrs, :last_change_at))
    end

    test "changeset/2 puts assoc to the domains where the concept is shared", %{attrs: attrs} do
      %{id: d1_id} = d1 = insert(:domain)
      %{id: d2_id} = d2 = insert(:domain)
      shared_to = [d1, d2]

      assert %{
               valid?: true,
               changes: %{shared_to: [%{data: %{id: ^d1_id}}, %{data: %{id: ^d2_id}}]}
             } =
               BusinessConcept.changeset(
                 %BusinessConcept{},
                 Map.put(attrs, :shared_to, shared_to)
               )
    end

    test "changeset/2 deletes assoc to the domains where the concept is shared" do
      d1 = insert(:domain)
      d2 = insert(:domain)
      concept = insert(:business_concept)
      insert(:shared_concept, business_concept: concept, domain: d1)
      insert(:shared_concept, business_concept: concept, domain: d2)
      concept = Repo.preload(concept, :shared_to)

      assert %{valid?: true, changes: %{shared_to: [%{action: :replace}, %{action: :replace}]}} =
               BusinessConcept.changeset(concept, %{shared_to: []})
    end
  end
end
