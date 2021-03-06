defmodule TdBg.CommentsFeatureTest do
  use Cabbage.Feature, async: false, file: "comments/comments.feature"
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

  setup do
    :ok
  end

  defwhen ~r/^"(?<admin_name>[^"]+)" tries to create a new comment "(?<comment>[^"]+)" on the business concept "(?<bc_name>[^"]+)"$/,
          %{admin_name: admin_name, comment: comment, bc_name: bc_name},
          state do
    token = Authentication.build_user_token(admin_name)
    business_concept = business_concept_version_by_name(token, bc_name)

    comment_params = %{
      "resource_id" => business_concept["business_concept_id"],
      "resource_type" => "business_concept",
      "system" => "comments",
      "content" => comment
    }

    {_, status_code, json_resp} = create_comment(token, comment_params)

    {:ok,
     Map.merge(
       state,
       %{status_code: status_code, resp: json_resp}
     )}
  end

  defand ~r/^the comment "(?<comment>[^"]+)" created by user "(?<user_name>[^"]+)" is present in the retrieved list$/,
         %{comment: comment, user_name: user_name},
         state do
    list_retrieved_comments = state[:resp]["data"]
    searched_comment = Enum.find(list_retrieved_comments, &(&1["content"] == comment))
    assert searched_comment
    assert searched_comment["user"]["user_name"] == user_name
  end

  defand ~r/^if result "(?<result>[^"]+)" the user "(?<user_name>[^"]+)" should be able to list the comments of the business concept "(?<bc_name>[^"]+)"$/,
         %{result: result, user_name: user_name, bc_name: bc_name},
         state do
    assert result == to_response_code(state[:status_code])
    token = Authentication.build_user_token(user_name)
    business_concept = business_concept_version_by_name(token, bc_name)

    {_, status_code, json_resp} =
      list_bc_comments(
        token,
        %{
          "resource_id" => business_concept["business_concept_id"],
          "resource_type" => "business_concept"
        }
      )

    {:ok,
     Map.merge(
       state,
       %{status_code: status_code, resp: json_resp}
     )}
  end

  defp list_bc_comments(token, params) do
    headers = Authentication.get_header(token)

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(
        Routes.comment_url(TdBgWeb.Endpoint, :index,
          resource_id: params["resource_id"],
          resource_type: params["resource_type"]
        ),
        headers,
        []
      )

    {:ok, status_code, resp |> Jason.decode!()}
  end

  defp create_comment(token, comment_params) do
    headers = Authentication.get_header(token)
    body = %{"comment" => comment_params} |> Jason.encode!()

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(Routes.comment_url(TdBgWeb.Endpoint, :create), body, headers, [])

    {:ok, status_code, resp |> Jason.decode!()}
  end
end
