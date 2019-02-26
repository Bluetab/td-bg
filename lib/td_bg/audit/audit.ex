defmodule TdBg.Audit do
  @moduledoc """
  Publishes events to the audit service
  """

  @td_audit_api Application.get_env(:td_bg, :audit_service)[:api_service]
  @service :td_bg

  def publish_event(event) do
    event =
      event
      |> Map.put(:service, @service)
      |> Map.put_new(:ts, DateTime.to_string(DateTime.utc_now()))

    @td_audit_api.post_audits(%{audit: event})
  end
end
