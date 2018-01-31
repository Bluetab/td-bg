defmodule TrueBG.BcContentSchema do
  @moduledoc false

  def bc_content_schema(:default) do
    [
      %{"name" => "Format", "type" => "list", "values" => ["Date", "Numeric", "Amount", "Text"], "required" => true},
      %{"name" => "List of Values", "type" => "variable list", "max_size" => 100},
      %{"name" => "Sensitive Data", "type" => "list", "values" => ["N/A", "Personal Data", "Related to personal Data"], "required" => true},
      %{"name" => "Update Frequence", "type" => "list", "values" => ["Not defined", "Daily", "Weekly", "Monthly", "Yearly"], "default" => "Not defined"},
      %{"name" => "Related Area", "type" => "string", "max_size" => 100},
      %{"name" => "Default Value", "type" => "string", "max_size" => 100},
      %{"name" => "Additional Data", "type" => "string", "max_size" => 500}
    ]
  end

  def bc_content_schema(:empty) do
    []
  end

end
