defmodule TdBg.Permissions do
  @moduledoc """
  The Permissions context.
  """

  alias TdBg.Auth.Claims

  @defaults %{
    "manage_business_concept_links" => :none,
    "manage_confidential_business_concepts" => :none,
    "view_approval_pending_business_concepts" => :none,
    "view_deprecated_business_concepts" => :none,
    "view_draft_business_concepts" => :none,
    "view_published_business_concepts" => :none,
    "view_rejected_business_concepts" => :none,
    "view_versioned_business_concepts" => :none
  }

  def get_default_permissions do
    {:ok, permissions} = TdCache.Permissions.get_default_permissions()
    Enum.into(permissions, @defaults, fn permission -> {permission, :all} end)
  end

  def get_session_permissions(%Claims{jti: jti}) do
    TdCache.Permissions.get_session_permissions(jti)
  end

  def has_permission?(%Claims{jti: jti}, permission) do
    TdCache.Permissions.has_permission?(jti, permission)
  end

  def has_any_permission?(%Claims{jti: jti}, permissions) do
    Enum.any?(permissions, &TdCache.Permissions.has_permission?(jti, &1))
  end

  @doc """
  Check if the authenticated user has a permission in a domain.

  ## Examples

      iex> authorized?(%Claims{}, "create", 12)
      false

  """
  def authorized?(%Claims{jti: jti}, permission, domain_id) do
    TdCache.Permissions.has_permission?(jti, permission, "domain", domain_id)
  end
end
