defmodule TdBg.Permissions do
  @moduledoc """
  The Permissions context.
  """

  alias TdBg.Auth.Claims

  @defaults [
    "manage_business_concept_links",
    "manage_confidential_business_concepts",
    "view_approval_pending_business_concepts",
    "view_deprecated_business_concepts",
    "view_draft_business_concepts",
    "view_published_business_concepts",
    "view_rejected_business_concepts",
    "view_versioned_business_concepts"
  ]

  def get_default_permissions, do: @defaults

  def has_permission?(%Claims{jti: jti}, permission) do
    TdCache.Permissions.has_permission?(jti, permission)
  end

  def has_any_permission?(%Claims{jti: jti}, permissions) do
    Enum.any?(permissions, &TdCache.Permissions.has_permission?(jti, &1))
  end

  def authorized?(%Claims{jti: jti}, permission, domain_id) do
    TdCache.Permissions.has_permission?(jti, permission, "domain", domain_id)
  end
end
