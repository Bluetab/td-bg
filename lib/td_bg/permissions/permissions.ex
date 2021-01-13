defmodule TdBg.Permissions do
  @moduledoc """
  The Permissions context.
  """

  alias TdBg.Auth.Session
  alias TdBg.Taxonomies.Domain

  @permission_resolver Application.compile_env(:td_bg, :permission_resolver)

  def get_domain_permissions(%Session{jti: jti}) do
    @permission_resolver.get_acls_by_resource_type(jti, "domain")
  end

  def has_any_permission_on_resource_type?(%Session{} = session, permissions, Domain) do
    session
    |> get_domain_permissions()
    |> Enum.flat_map(& &1.permissions)
    |> Enum.uniq()
    |> Enum.any?(&Enum.member?(permissions, &1))
  end

  @doc """
  Check if the authenticated user has a permission in a domain.

  ## Examples

      iex> authorized?(%Session{}, "create", 12)
      false

  """
  def authorized?(%Session{jti: jti}, permission, domain_id) do
    @permission_resolver.has_permission?(jti, permission, "domain", domain_id)
  end
end
