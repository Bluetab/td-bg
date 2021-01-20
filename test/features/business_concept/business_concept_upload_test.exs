defmodule TdBg.BusinessConceptUploadTest do
  use Cabbage.Feature, file: "business_concept/business_concept_upload.feature"
  use TdBgWeb.FeatureCase

  import TdBg.BusinessConceptSteps
  import TdBg.ResultSteps
  import TdBgWeb.BusinessConcept
  import TdBgWeb.ResponseCode
  import TdBgWeb.Taxonomy, only: :functions

  alias TdBg.Cache.ConceptLoader
  alias TdBg.Cache.DomainLoader
  alias TdBg.Search.IndexWorker

  import_steps(TdBg.BusinessConceptSteps)
  import_steps(TdBg.DomainSteps)
  import_steps(TdBg.ResultSteps)
  import_steps(TdBg.UsersSteps)

  setup_all do
    start_supervised(ConceptLoader)
    start_supervised(DomainLoader)
    start_supervised(IndexWorker)
    :ok
  end
end
