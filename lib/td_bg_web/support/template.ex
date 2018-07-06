defmodule TdBgWeb.TemplateSupport do
  @moduledoc false

  alias TdBg.Accounts.User
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Permissions.AclEntry
  alias TdBg.Permissions.Role
  alias TdBg.Repo
  alias TdBg.Taxonomies.Domain
  alias TdBg.Templates

  @td_auth_api Application.get_env(:td_bg, :auth_service)[:api_service]

  def preprocess_templates(templates, ctx \\ []) do
    process_template_meta([], templates, ctx)
  end

  defp process_template_meta(acc, [], _contetx), do: acc
  defp process_template_meta(acc, [head|tail], ctx) do
    acc
    |> process_template_meta(head, ctx)
    |> process_template_meta(tail, ctx)
  end
  defp process_template_meta(acc, template, ctx) do
    content = process_meta([], template.content, ctx)
    processed = Map.put(template, :content, content)
    [processed|acc]
  end

  defp process_meta(acc, [], _ctx), do: acc
  defp process_meta(acc, [head|tail], ctx) do
    acc
    |> process_meta(head, ctx)
    |> process_meta(tail, ctx)
  end
  defp process_meta(acc, %{"type" => type, "meta" => meta} = field, ctx) do
    field = case {type, meta} do
      {"list", %{"role" => rolename}} ->
        user = Keyword.get(ctx, :user, nil)
        role = Role.get_role_by_name(rolename)
        domain = Keyword.get(ctx, :domain, nil)
        process_role_meta(field, user, role, domain)
      _ -> field
    end
    field_without_meta = Map.delete(field, "meta")
    acc ++ [field_without_meta]
  end
  defp process_meta(acc, %{} = field, _ctx) do
    acc ++ [field]
  end

  # TODO: Refactor (roles and ACL entries are now in td_auth)
  defp process_role_meta(%{} = field, %User{} = user,  %Role{} = role,  %Domain{} = domain)
    when not is_nil(user) and
         not is_nil(role) and
         not is_nil(domain) do
    acl_entries = get_acl_entries(role, domain)
    user_and_groups = Enum.group_by(acl_entries, &(&1.principal_type), &(&1.principal_id))
    group_ids = Map.get(user_and_groups, "group", [])
    user_ids  = Map.get(user_and_groups, "user", [])
    users = @td_auth_api.get_groups_users(group_ids, user_ids)
    usernames = Enum.map(users, &Map.get(&1, :full_name))
    field = Map.put(field, "values", usernames)
    case Enum.find(users, &(&1.id == user.id)) do
      nil -> field
      u -> Map.put(field, "default", u.full_name)
    end
  end
  defp process_role_meta(field, _user, _role, _domain), do: field

  defp get_acl_entries(role, domain) do
    acl_entries = AclEntry.list_acl_entries(%{domain: domain, role: role})
    case domain.parent_id do
      nil -> acl_entries
      _ ->
        parent = domain |> Repo.preload(:parent) |> Map.get(:parent)
        acl_entries ++ get_acl_entries(role, parent)
    end
  end

  # TODO: unit test this
  def get_preprocessed_template(%BusinessConceptVersion{} = version, %User{} = user) do
    domain = version.business_concept
    |> Repo.preload(:domain)
    |> Map.get(:domain)

    template = version.business_concept.type
    |> Templates.get_template_by_name

    process_template_meta([], [template], domain: domain, user: user)
    |> Enum.at(0)
  end

  # TODO: unit test this
  def get_template(%BusinessConceptVersion{} = version) do
    version
    |> Map.get(:business_concept)
    |> Map.get(:type)
    |> Templates.get_template_by_name
  end

end
