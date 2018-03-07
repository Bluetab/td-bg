defmodule TdBGWeb.BCStatusCode do
  @moduledoc false

  @draft "draft"
  @pending_approval "pending approval"
  @rejected "rejected"
  @published "published"
  @deprecated "deprecated"
  @deleted "deleted"

  def to_status_string(bc_status_code) do
    case bc_status_code do
      :draft -> @draft
      :pending_approval -> @pending_approval
      :rejected -> @rejected
      :published -> @published
      :deprecated -> @deprecated
      :deleted -> @deleted
      _ -> "Unknown Status"
    end
  end

end
