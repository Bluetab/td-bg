defmodule TdBg.Templates.Template do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias TdBg.Templates.Template

  schema "templates" do
    field :content, {:array, :map}
    field :name, :string
    field :is_default, :boolean

    timestamps()
  end

  @doc false
  def changeset(%Template{} = template, attrs) do
    template
    |> cast(attrs, [:name, :content, :is_default])
    |> validate_required([:name, :content, :is_default])
  end
end
