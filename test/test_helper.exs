{:ok, _} = Application.ensure_all_started(:ex_machina)
Mox.defmock(TdBg.ElasticsearchMock, for: Elasticsearch.API)

ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(TdBg.Repo, :manual)
