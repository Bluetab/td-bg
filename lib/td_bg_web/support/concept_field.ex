defmodule TdBgWeb.ConceptFieldSupport do
  @moduledoc false
  alias TdBg.Utils.CollectionUtils

  def normalize_field(%{} = field) do
    field = CollectionUtils.atomize_keys(field)
    [field.system,
     field.group,
     field.structure,
     field.name]
    |> Enum.join("::")
  end

  def denormalize_field(field) when is_binary(field) do
    splited_field = String.split(field, "::")
    %{system: Enum.at(splited_field, 0),
      group: Enum.at(splited_field, 1),
      structure: Enum.at(splited_field, 2),
      name: Enum.at(splited_field, 3)}
  end

end
