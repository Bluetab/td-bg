defmodule TdBg.ChangesetSupportTest do
  use TdBg.DataCase

  describe "chanset support" do
    alias Ecto.Changeset
    alias TdBgWeb.ChangesetSupport

    test "translate_errors/1 when no errors" do
      data  = %{}
      types = %{first_name: :string}
      errors = {data, types}
      |> Changeset.cast(%{first_name: "Bob"}, Map.keys(types))
      |> validate_required([:first_name])
      |> ChangesetSupport.translate_errors

      expected_errors = []

      assert errors == expected_errors
    end

    test "translate_errors/1 translate one required error" do
      data  = %{}
      types = %{first_name: :string}
      errors = {data, types}
      |> Changeset.cast(%{}, Map.keys(types))
      |> validate_required([:first_name])
      |> ChangesetSupport.translate_errors

      expected_errors = [
        %{
          code: "undefined",
          name: "error.first_name.required"
        }
      ]

      assert errors == expected_errors
    end

    test "translate_errors/1 translate one required error with prefix" do
      data  = %{}
      types = %{first_name: :string}
      errors = {data, types}
      |> Changeset.cast(%{}, Map.keys(types))
      |> validate_required([:first_name])
      |> ChangesetSupport.translate_errors("blah.blah.error")

      expected_errors = [
        %{
          code: "undefined",
          name: "blah.blah.error.first_name.required"
        }
      ]

      assert errors == expected_errors
    end

    test "translate_errors/1 translate two required error" do
      data  = %{}
      types = %{first_name: :string, second_name: :string}
      errors = {data, types}
      |> Changeset.cast(%{}, Map.keys(types))
      |> validate_required([:first_name, :second_name])
      |> ChangesetSupport.translate_errors

      expected_errors = [
        %{
          code: "undefined",
          name: "error.first_name.required"
        },
        %{
          code: "undefined",
          name: "error.second_name.required"
        }
      ]

      assert errors == expected_errors
    end

    test "translate_errors/1 translate cast error" do
      data  = %{}
      types = %{first_name: :string}
      errors = {data, types}
      |> Changeset.cast(%{first_name: 1}, Map.keys(types))
      |> validate_required([:first_name])
      |> ChangesetSupport.translate_errors

      expected_errors = [
        %{
          code: "undefined",
          name: "error.first_name.cast.string"
        }
      ]

      assert errors == expected_errors
    end

  end

end
