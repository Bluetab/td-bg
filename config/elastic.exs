import Config

config :td_core, TdCore.Search.Cluster,
  # The default URL where Elasticsearch is hosted on your system.
  # Will be overridden by the `ES_URL` environment variable if set.
  url: "http://elastic:9200",

  # If you want to mock the responses of the Elasticsearch JSON API
  # for testing or other purposes, you can inject a different module
  # here. It must implement the Elasticsearch.API behaviour.
  api: Elasticsearch.API.HTTP,

  # The library used for JSON encoding/decoding.
  json_library: Jason,
  aliases: %{
    concepts: "concepts"
  }

config :td_core, TdCore.Search.Cluster,
  # You should configure each index which you maintain in Elasticsearch here.
  # This configuration will be read by the `mix elasticsearch.build` task,
  # described below.
  indexes: [
    # This is the base name of the Elasticsearch index. Each index will be
    # built with a timestamp included in the name, like "posts-5902341238".
    # It will then be aliased to "posts" for easy querying.
    concepts: [
      template_scope: :bg,

      # This map describes the mappings and settings for your index. It will
      # be posted as-is to Elasticsearch when you create your index, and
      # therefore allows all the settings you could post directly.
      settings: %{
        analysis: %{
          analyzer: %{
            default: %{
              type: "custom",
              tokenizer: "whitespace",
              filter: ["lowercase", "word_delimiter", "asciifolding"]
            },
            es_analyzer: %{
              type: "custom",
              tokenizer: "whitespace",
              filter: ["lowercase", "word_delimiter", "asciifolding", "es_stem"]
            },
            en_analyzer: %{
              type: "custom",
              tokenizer: "whitespace",
              filter: ["lowercase", "word_delimiter", "asciifolding", "porter_stem"]
            }
          },
          normalizer: %{
            sortable: %{type: "custom", char_filter: [], filter: ["lowercase", "asciifolding"]}
          },
          filter: %{
            es_stem: %{
              type: "stemmer",
              language: "light_spanish"
            }
          }
        }
      },

      # This store module must implement a store behaviour. It will be used to
      # fetch data for each source in each indexes' `sources` list, below:
      store: TdBg.Search.Store,

      # This is the list of data sources that should be used to populate this
      # index. The `:store` module above will be passed each one of these
      # sources for fetching.
      #
      # Each piece of data that is returned by the store must implement the
      # Elasticsearch.Document protocol.
      sources: [TdBg.BusinessConcepts.BusinessConceptVersion],

      # Likewise, wait a given period between posting pages to give
      # Elasticsearch time to catch up.
      bulk_wait_interval: 0,

      # Support create or replace
      bulk_action: "index"
    ]
  ]
