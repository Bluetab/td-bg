defmodule TdBg.Templates.Template do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias TdBg.Templates.Template

  schema "templates" do
    field :content, {:array, :map}
    field :label, :string
    field :name, :string
    field :is_default, :boolean

    timestamps()
  end

  @doc false
  def changeset(%Template{} = template, attrs) do
    template
    |> cast(attrs, [:label, :name, :content, :is_default])
    |> validate_required([:label, :name, :content, :is_default])
    |> validate_format(:name, ~r/^[A-z0-9]*$/)
    |> unique_constraint(:label)
    |> unique_constraint(:name)
    |> unique_constraint(:is_default)
  end
end
