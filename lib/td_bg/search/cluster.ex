defmodule TdBg.Search.Cluster do
  @moduledoc "Elasticsearch cluster configuration for TdBg"

  use Elasticsearch.Cluster, otp_app: :td_bg
end
