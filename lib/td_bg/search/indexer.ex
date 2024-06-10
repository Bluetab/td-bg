defmodule TdBg.Search.Indexer do
  @moduledoc """
  Indexer for Concepts.
  """

  alias TdCore.Search.IndexWorker

  @index :concepts

  def reindex(ids) do
    IndexWorker.reindex(@index, ids)
  end

  def delete(ids) do
    IndexWorker.delete(@index, ids)
  end
end
