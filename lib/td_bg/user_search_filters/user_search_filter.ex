defmodule TdBg.UserSearchFilters.UserSearchFilter do
  @moduledoc """
  Module for saving user search filters of Concepts
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias TdDfLib.Validation

  schema "user_search_filters" do
    field(:filters, :map)
    field(:name, :string)
    field(:user_id, :integer)
    field(:is_global, :boolean)

    timestamps()
  end

  @doc false
  def changeset(user_search_filter, attrs) do
    user_search_filter
    |> cast(attrs, [:name, :filters, :user_id, :is_global])
    |> validate_required([:name, :filters, :user_id])
    |> unique_constraint([:name, :user_id], name: :user_search_filters_name_user_id_index)
    |> validate_change(:filters, &Validation.validate_safe/2)
  end
end
