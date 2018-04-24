defmodule Mix.Tasks.Bg.EsInit do
  use Mix.Task
  alias TdBg.ESClientApi

  @shortdoc "Initialize ES indexes"

  @moduledoc """
    Run
  """

  def run(_args) do
    Mix.Task.run "app.start"

    ESClientApi.create_indexes

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
#        domain_id: %{type: "integer"},
#        name: %{type: "text"},
#        status: %{type: "text"},
#        type: %{type: "text"},
#        content: %{type: "object"},
#        description: %{type: "text"},
#        last_change_at: %{type: "date"}
#      }
#    }
#      domain_mapping = %{
#      properties: %{
#        name: %{type: "text"},
#        type: %{type: "text"},
#        description: %{type: "text"},
#        parent_id: %{type: "integer"}
#      }
#    }
#
#      doc_types = ["business_concept", "domain"]
#    mappings = [ {"business_concept", business_concept_mapping},
#                 {"domain", domain_mapping}
#    ]
#    doc_type = "_doc"
#     Enum.map(mappings, fn({index_name, mapping})->
#     Elastix.Index.create(elastic_url, index_name, %{})
#     {:ok, %HTTPoison.Response{status_code: status_code, body: resp}}
#       = Elastix.Mapping.put(elastic_url, index_name, doc_type, mapping)
#     end)
  end

end
