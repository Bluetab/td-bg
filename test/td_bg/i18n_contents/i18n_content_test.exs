defmodule TdBg.I18nContents.I18nContentTest do
  use TdBg.DataCase

  alias TdBg.I18nContents.I18nContent

  describe "TdBg.I18nContents.I18nContentTest" do
    setup do
      bcv = insert(:business_concept_version)
      [bcv: bcv]
    end

    test "changeset/2 creates changeset", %{bcv: %{id: bcv_id}} do
      attrs = %{
        lang: "foo",
        name: "foo_name",
        content: %{"bar" => "xyz"},
        business_concept_version_id: bcv_id
      }

      assert %{
               valid?: true,
               changes: %{
                 name: "foo_name",
                 content: %{"bar" => "xyz"},
                 lang: "foo",
                 business_concept_version_id: ^bcv_id
               }
             } = I18nContent.changeset(attrs)
    end

    test "changeset/2 validate required fields" do
      assert %{valid?: false, errors: errors} = I18nContent.changeset(%{})

      assert errors[:lang] == {"can't be blank", [validation: :required]}
      assert errors[:content] == {"can't be blank", [validation: :required]}
      assert errors[:business_concept_version_id] == {"can't be blank", [validation: :required]}
    end

    test "changeset/2 validate constraint", %{bcv: %{id: bcv_id}} do
      %{lang: lang} = insert(:i18n_content, %{business_concept_version_id: bcv_id})

      params = %{
        lang: lang,
        name: "other name",
        content: %{"bar" => "xyz"},
        business_concept_version_id: bcv_id
      }

      assert {:error, %{errors: errors}} =
               params
               |> I18nContent.changeset()
               |> Repo.insert()

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
end
