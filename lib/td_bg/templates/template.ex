defmodule TdBg.Templates.Template do
  @moduledoc false
  
  use Ecto.Schema
  import Ecto.Changeset
  alias TdBg.Templates.Template

  schema "templates" do
    field :content, {:array, :map}
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(%Template{} = template, attrs) do
    template
    |> cast(attrs, [:name, :content])
    |> validate_required([:name, :content])
  end
end
