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
      name: %{type: "text", fields: %{raw: %{type: "keyword", normalizer: "sortable"}}},
      description: %{type: "text"},
      version: %{type: "short"},
      template: %{
        properties: %{
          name:  %{type: "text"},
          label: %{type: "text", fields: %{raw: %{type: "keyword"}}}
        }
      },
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
      domain_parents: %{
        properties: %{
          id: %{type: "long"},
          name: %{type: "text"}
        }
      },
      link_count: %{type: "short"},
      q_rule_count: %{type: "short"},
      content: content_mappings
    }

    settings = %{
      analysis: %{
        normalizer: %{
          sortable: %{type: "custom", char_filter: [], filter: ["lowercase", "asciifolding"]}
        }
      }
    }

    %{mappings: %{doc: %{properties: mapping_type}}, settings: settings}
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
