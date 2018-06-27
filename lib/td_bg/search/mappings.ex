defmodule TdBg.Search.Mappings do
  @moduledoc """
    Generates mappings for elasticsearch
  """
  alias TdBg.Templates
  alias TdBg.Templates.Template

  def get_mappings do
    content_mappings = %{properties: get_dynamic_mappings()}

    mapping_type = %{
      id: %{type: "long"},
      name: %{type: "text"},
      description: %{type: "text"},
      version: %{type: "short"},
      type: %{type: "keyword"},
      status: %{type: "keyword"},
      last_change_at: %{type: "date", format: "strict_date_optional_time||epoch_millis"},
      current: %{type: "boolean"},
      domain: %{
        properties: %{
          id: %{type: "long"},
          name: %{type: "text", fields: %{raw: %{type: "keyword"}}}
        }
      },
      last_change_by: %{
        properties: %{
          id: %{type: "long"},
          user_name: %{type: "text", fields: %{raw: %{type: "keyword"}}},
          full_name: %{type: "text", fields: %{raw: %{type: "keyword"}}}
        }
      },
      domain_ids: %{type: "long"},
      content: content_mappings
    }

    %{mappings: %{doc: %{properties: mapping_type}}}
  end

  def get_dynamic_mappings do
    Templates.list_templates()
    |> Enum.flat_map(&get_mappings/1)
    |> Enum.into(%{})
  end

  defp get_mappings(%Template{content: content}) do
    content
    |> Enum.map(&field_mapping/1)
  end

  defp field_mapping(%{"name" => name, "type" => type}) do
    {name, mapping_type(type)}
  end

  defp mapping_type("list") do
    %{type: "text", fields: %{raw: %{type: "keyword"}}}
  end

  defp mapping_type(_default), do: %{type: "text"}
end
