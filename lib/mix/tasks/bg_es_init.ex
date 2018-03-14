defmodule Mix.Tasks.Bg.EsInit do
  use Mix.Task
  alias TdBg.Search

  @shortdoc "Initialize ES indexes"

  @moduledoc """
    Run
  """

  def run(_args) do
    Mix.Task.run "app.start"

    Search.create_indexes
    
# create indexes if we use library  {:elastix, "~> 0.5"}
#
#    elastic_url = "http://127.0.0.1:9200"
#      # Elastic Index Name
#    index_name = "td_bg"
#      # Elastic Document Type
#    #doc_type = "business_concept"
#      # Add mapping
#    business_concept_mapping = %{
#      properties: %{
#        data_domain_id: %{type: "integer"},
#        name: %{type: "text"},
#        status: %{type: "text"},
#        type: %{type: "text"},
#        content: %{type: "object"},
#        description: %{type: "text"},
#        last_change_at: %{type: "date"}
#      }
#    }
#      domain_group_mapping = %{
#      properties: %{
#        name: %{type: "text"},
#        description: %{type: "text"},
#        parent_id: %{type: "integer"}
#      }
#    }
#      data_domain_mapping = %{
#      properties: %{
#        name: %{type: "text"},
#        description: %{type: "text"},
#        domain_group_id: %{type: "integer"}
#      }
#    }
#      doc_types = ["business_concept", "domain_group", "data_domain"]
#    mappings = [ {"business_concept", business_concept_mapping},
#                 {"domain_group", domain_group_mapping},
#                 {"data_domain", data_domain_mapping}
#    ]
#    doc_type = "_doc"
#     Enum.map(mappings, fn({index_name, mapping})->
#     Elastix.Index.create(elastic_url, index_name, %{})
#     {:ok, %HTTPoison.Response{status_code: status_code, body: resp}}
#       = Elastix.Mapping.put(elastic_url, index_name, doc_type, mapping)
#     end)
  end

end
