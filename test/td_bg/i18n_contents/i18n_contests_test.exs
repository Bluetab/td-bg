defmodule TdBg.I18nContents.I18nContestsTest do
  use TdBg.DataCase
  import TdBg.TestOperators

  alias TdBg.BusinessConcepts
  alias TdBg.I18nContents.I18nContent
  alias TdBg.I18nContents.I18nContents

  setup _context do
    on_exit(fn ->
      TdCache.Redix.del!("i18n:locales:*")
    end)

    :ok
  end

  setup do
    bcv = insert(:business_concept_version)
    [bcv: bcv]
  end

  describe "create i18n_content" do
    test "with valid data creates i18n_content", %{bcv: %{id: bcv_id}} do
      attrs = %{
        lang: "foo",
        name: "foo_name",
        content: %{"bar" => "xyz"},
        business_concept_version_id: bcv_id
      }

      assert {:ok,
              %I18nContent{business_concept_version_id: ^bcv_id, lang: "foo", name: "foo_name"}} =
               I18nContents.create_i18n_content(attrs)
    end

    test "with valid data creates i18n_content with diferent lanf", %{bcv: %{id: bcv_id}} do
      %{name: name} = insert(:i18n_content, business_concept_version_id: bcv_id)

      attrs = %{
        lang: "bar",
        name: name,
        content: %{"bar" => "xyz"},
        business_concept_version_id: bcv_id
      }

      assert {:ok, %I18nContent{business_concept_version_id: ^bcv_id, lang: "bar", name: ^name}} =
               I18nContents.create_i18n_content(attrs)
    end

    test "with invalid data" do
      assert {:error, %Ecto.Changeset{} = changeset} = I18nContents.create_i18n_content(%{})

      assert %{valid?: false, errors: errors} = changeset
      assert errors[:lang] == {"can't be blank", [validation: :required]}
      assert errors[:content] == {"can't be blank", [validation: :required]}
      assert errors[:business_concept_version_id] == {"can't be blank", [validation: :required]}
    end

    test "validate constraint data", %{bcv: %{id: bcv_id}} do
      %{name: name, lang: lang} = insert(:i18n_content, business_concept_version_id: bcv_id)

      attrs = %{
        name: name,
        lang: lang,
        content: %{"foo" => "bar"},
        business_concept_version_id: bcv_id
      }

      assert {:error, %{errors: errors}} = I18nContents.create_i18n_content(attrs)

      assert [
               business_concept_version_id:
                 {"has already been taken",
                  [
                    constraint: :unique,
                    constraint_name: "i18n_contents_business_concept_version_id_lang_index"
                  ]}
             ] = errors
    end
  end

  describe "update i18n_content" do
    test "update_i18n_content/2 returns updated data", %{bcv: %{id: bcv_id}} do
      i18n_content = insert(:i18n_content, business_concept_version_id: bcv_id)

      content = %{"bar" => "foo"}
      name = "new_name"
      attrs = %{content: content, name: name}

      {:ok, %{content: ^content, name: ^name}} =
        I18nContents.update_i18n_content(i18n_content, attrs)
    end
  end

  describe "get i18n_content" do
    test "get_by_i18n_content!/1 returns especific content by lang and business_concept_id", %{
      bcv: %{id: bcv_id}
    } do
      %{id: i18n_content_id, lang: lang} =
        insert(:i18n_content, business_concept_version_id: bcv_id)

      assert %{id: ^i18n_content_id} =
               I18nContents.get_by_i18n_content!(lang: lang, business_concept_version_id: bcv_id)
    end
  end

  describe "i18n_content" do
    test "when gcv is deleted all i18n_content is deleted", %{bcv: %{id: bcv_id} = dsv} do
      claims = build(:claims, role: "admin")

      i18n_content_1 = insert(:i18n_content, business_concept_version_id: bcv_id)

      i18n_content_2 = insert(:i18n_content, lang: "es", business_concept_version_id: bcv_id)

      assert [i18n_content_1, i18n_content_2] |||
               I18nContents.get_all_i18n_content_by_bcv_id(bcv_id)

      BusinessConcepts.delete_business_concept_version(dsv, claims)
      assert [] == I18nContents.get_all_i18n_content_by_bcv_id(bcv_id)
    end
  end
end
