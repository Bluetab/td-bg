defmodule TdBgWeb.BusinessConceptDataFieldSupport do
  @moduledoc false
  alias TdBg.Utils.CollectionUtils

  def normalize_data_field(%{} = data_field) do
    data_field = CollectionUtils.atomize_keys(data_field)
    [data_field.system,
     data_field.group,
     data_field.structure,
     data_field.name]
    |> Enum.join("::")
  end

  def denormalize_data_field(data_field) when is_binary(data_field) do
    splited_data_field = String.split(data_field, "::")
    %{system: Enum.at(splited_data_field, 0),
      group: Enum.at(splited_data_field, 1),
      structure: Enum.at(splited_data_field, 2),
      name: Enum.at(splited_data_field, 3)}
  end

end
