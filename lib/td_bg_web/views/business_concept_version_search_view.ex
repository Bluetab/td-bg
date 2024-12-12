defmodule TdBgWeb.BusinessConceptVersionSearchView do
  require Logger
  use TdBgWeb, :view
  use TdHypermedia, :view

  alias TdCache.I18nCache

  def render("list.json", %{scroll_id: scroll_id} = assigns) do
    "list.json"
    |> render(Map.delete(assigns, :scroll_id))
    |> Map.put("scroll_id", scroll_id)
  end

  def render("list.json", %{hypermedia: hypermedia} = assigns) do
    render_many_hypermedia(hypermedia, __MODULE__, "list_item.json", %{
      lang: Map.get(assigns, :locale)
    })
  end

  def render(
        "list_item.json",
        %{business_concept_version_search: business_concept_version} = assigns
      ) do
    lang = Map.get(assigns, :lang)

    view_fields = [
      "_actions",
      "id",
      "name",
      "domain",
      "status",
      "rule_count",
      "link_count",
      "link_tags",
      "links",
      "concept_count",
      "content",
      "last_change_by",
      "last_change_at",
      "inserted_at",
      "updated_at",
      "domain_parents",
      "in_progress"
    ]

    type = get_in(business_concept_version, ["template", "name"])
    type_label = get_in(business_concept_version, ["template", "label"])
    test_fields = ["business_concept_id", "current", "version"]

    business_concept_version
    |> set_i18n_property("name", lang)
    |> set_i18n_content(lang)
    |> Map.take(view_fields ++ test_fields)
    |> Map.put("type", type)
    |> Map.put("type_label", type_label)
  end

  defp set_i18n_property(concept, property, lang) do
    default_value = Map.get(concept, property)

    Map.put(concept, property, Map.get(concept, "#{property}_#{lang}", default_value))
  end

  defp set_i18n_content(%{"content" => content} = concept, lang) do
    if is_nil(lang),
      do: Logger.error("Language is not defined in the business_concept_version_search_view")

    {:ok, default_lang} = I18nCache.get_default_locale()

    if lang == default_lang or is_nil(lang) do
      new_content =
        content
        |> Enum.filter(fn {key, _value} -> not String.match?(key, ~r/_[a-z]{2}$/) end)
        |> Enum.into(%{})

      Map.put(concept, "content", new_content)
    else
      suffix = "_#{lang}"

      new_content =
        content
        |> Enum.filter(fn {key, _value} -> String.ends_with?(key, suffix) end)
        |> Enum.map(fn {key, value} -> {String.replace_suffix(key, suffix, ""), value} end)
        |> Enum.into(%{})

      Map.put(concept, "content", new_content)
    end
  end
end
