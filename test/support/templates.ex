defmodule Templates do
  @moduledoc """
  Template support for Business Glossary tests
  """

  alias ExUnit.Callbacks
  alias TdCache.TemplateCache

  @content [
    %{
      "name" => "group",
      "fields" => [
        %{
          name: "foo",
          type: "string",
          cardinality: "?",
          values: %{"fixed" => ["bar"]},
          subscribable: true
        },
        %{
          name: "xyz",
          type: "string",
          cardinality: "?",
          values: %{"fixed" => ["foo"]}
        }
      ]
    }
  ]

  def create_template(%{id: _} = attrs) do
    put_template(attrs)
  end

  def create_template(type, content \\ @content) do
    attrs = %{
      id: 0,
      label: type,
      name: type,
      scope: "test",
      content: content
    }

    put_template(attrs)
  end

  def create_template do
    attrs = %{
      id: 0,
      label: "some type",
      name: "some_type",
      scope: "test",
      content: []
    }

    put_template(attrs)
  end

  def delete(template_id) do
    TemplateCache.delete(template_id)
  end

  defp put_template(%{id: id, updated_at: _updated_at} = attrs) do
    case TemplateCache.put(attrs, publish: false) do
      {:ok, _} -> Callbacks.on_exit(fn -> TemplateCache.delete(id) end)
    end

    Map.delete(attrs, :updated_at)
  end

  defp put_template(%{} = attrs) do
    attrs
    |> Map.put(:updated_at, DateTime.utc_now())
    |> put_template()
  end
end
