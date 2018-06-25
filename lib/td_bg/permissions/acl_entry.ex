defmodule TdBg.Permissions.AclEntry do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias TdBg.Accounts.User
  alias TdBg.Permissions.AclEntry
  alias TdBg.Permissions.Role
  alias TdBg.Repo

  @td_auth_api Application.get_env(:td_bg, :auth_service)[:api_service]

  schema "acl_entries" do
    field :principal_id, :integer
    field :principal_type, :string
    field :resource_id, :integer
    field :resource_type, :string
    belongs_to :role, Role

    timestamps()
  end

  @doc false
  def changeset(%AclEntry{} = acl_entry, attrs) do
    acl_entry
    |> cast(attrs, [:principal_type, :principal_id, :resource_type, :resource_id, :role_id])
    |> validate_required([:principal_type, :principal_id, :resource_type, :resource_id, :role_id])
    |> validate_inclusion(:principal_type, ["user", "group"])
    |> validate_inclusion(:resource_type, ["domain"])
    |> unique_constraint(:unique_principal_resource, name: :principal_resource_index)
  end

  @doc """
  Returns the list of acl_entries.

  ## Examples

      iex> list_acl_entries()
      [%Acl_entry{}, ...]

  """
  def list_acl_entries do
    Repo.all(AclEntry)
  end

  @doc """
    Returns a list of users-role with acl_entries in the domain and role passed as argument

    This return acl with resource type domain and  principal types user or group
  """
  def list_acl_entries(%{domain: domain, role: role}) do
    Repo.all(from acl_entry in AclEntry,
      where: acl_entry.resource_type == "domain" and
             acl_entry.resource_id == ^domain.id and
             acl_entry.role_id == ^role.id)
  end

  @doc """
    Returns a list of users-role with acl_entries in the domain passed as argument
  """
  def list_acl_entries(%{domain: domain}) do
    list_acl_entries(%{domain: domain}, :role)
  end

  @doc """
    Returns a list of users-role with acl_entries in the domain passed as argument, configurable preloading
  """
  def list_acl_entries(%{domain: domain}, preload) do
    acl_entries =
      Repo.all(
        from(
          acl_entry in AclEntry,
          where: acl_entry.resource_type == "domain" and acl_entry.resource_id == ^domain.id
        )
      )

    acl_entries |> Repo.preload(preload)
  end

  @doc """
    Returns a list of acl_entries querying by several principal_types
  """
  def list_acl_entries_by_principal_types(%{principal_types: principal_types}) do
    Repo.all(
      from(
        acl_entry in AclEntry,
        join: role in assoc(acl_entry, :role),
        join: permission in assoc(role, :permissions),
        where: acl_entry.principal_type in ^principal_types,
        preload: [role: {role, permissions: permission}]
      )
    )
  end

  @doc """

  """
  def list_acl_entries_by_principal(%{principal_id: principal_id, principal_type: principal_type}) do
    acl_entries =
      Repo.all(
        from(
          acl_entry in AclEntry,
          where:
            acl_entry.principal_type == ^principal_type and
              acl_entry.principal_id == ^principal_id
        )
      )

    acl_entries |> Repo.preload(role: [:permissions])
  end

  def list_acl_entries_by_user(%{user_id: user_id}) do
    list_acl_entries_by_principal(%{principal_id: user_id, principal_type: "user"})
  end

  def list_acl_entries_by_group(%{group_id: group_id}) do
    list_acl_entries_by_principal(%{principal_id: group_id, principal_type: "group"})
  end

  def list_acl_entries_by_user_with_groups(%{user_id: user_id}) do
    user = @td_auth_api.get_user(user_id)
    group_ids = User.get_group_ids(user)
    user_acl_entries = list_acl_entries_by_user(%{user_id: user_id})

    group_acl_entries =
      group_ids
      |> Enum.flat_map(&list_acl_entries_by_group(%{group_id: &1}))

    user_acl_entries ++ group_acl_entries
  end

  @doc """
  Gets a single acl_entry.

  Raises `Ecto.NoResultsError` if the Acl entry does not exist.

  ## Examples

      iex> get_acl_entry!(123)
      %Acl_entry{}

      iex> get_acl_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_acl_entry!(id), do: Repo.get!(AclEntry, id)

  @doc """
  Creates a acl_entry.

  ## Examples

      iex> create_acl_entry(%{field: value})
      {:ok, %Acl_entry{}}

      iex> create_acl_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_acl_entry(attrs \\ %{}) do
    %AclEntry{}
    |> AclEntry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a acl_entry.

  ## Examples

      iex> update_acl_entry(acl_entry, %{field: new_value})
      {:ok, %Acl_entry{}}

      iex> update_acl_entry(acl_entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_acl_entry(%AclEntry{} = acl_entry, attrs) do
    acl_entry
    |> AclEntry.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Acl_entry.

  ## Examples

      iex> delete_acl_entry(acl_entry)
      {:ok, %Acl_entry{}}

      iex> delete_acl_entry(acl_entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_acl_entry(%AclEntry{} = acl_entry) do
    Repo.delete(acl_entry)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking acl_entry changes.

  ## Examples

      iex> change_acl_entry(acl_entry)
      %Ecto.Changeset{source: %Acl_entry{}}

  """
  def change_acl_entry(%AclEntry{} = acl_entry) do
    AclEntry.changeset(acl_entry, %{})
  end

  def get_list_acl_from_domain(domain) do
    acl_entries = list_acl_entries(%{domain: domain})
    acl_entries_map_ids = acl_entries |> Enum.group_by(& &1.principal_type, & &1.principal_id)

    users =
      case acl_entries_map_ids["user"] do
        nil -> []
        user_ids -> @td_auth_api.search_users(%{"ids" => user_ids})
      end

    groups =
      case acl_entries_map_ids["group"] do
        nil -> []
        group_ids -> @td_auth_api.search_groups(%{"ids" => group_ids})
      end

    Enum.reduce(acl_entries, [], fn u, acc ->
      principal =
        case u.principal_type do
          "user" -> Enum.find(users, fn r_u -> r_u.id == u.principal_id end)
          "group" -> Enum.find(groups, fn r_u -> r_u.id == u.principal_id end)
        end

      if principal do
        acc ++
          [
            %{
              principal: principal,
              principal_type: u.principal_type,
              role_id: u.role.id,
              role_name: u.role.name,
              acl_entry_id: u.id
            }
          ]
      else
        acc
      end
    end)
  end

  def acl_matches?(%{principal_type: "user", principal_id: user_id}, user_id, _group_ids), do: true

  def acl_matches?(%{principal_type: "group", principal_id: group_id}, _user_id, group_ids) do
    group_ids
    |> Enum.any?(&(&1 == group_id))
  end

  def acl_matches?(_, _, _), do: false

end
