defmodule TdBg.BusinessConcept.RichText do
  @moduledoc """
    Helper module to manipulate rich text.
  """

  def to_rich_text(nil), do: %{}
  def to_rich_text(""),  do: %{}
  def to_rich_text(text) when is_binary(text) do
    nodes = text
    |> String.split("\n")
    |> Enum.map(fn(text) ->
      %{"object" => "block",
        "type" => "paragraph",
        "nodes" => [%{"object" => "text", "leaves" => [%{"text" => text}]}]}
    end)
    %{"document" => %{"nodes" => nodes}}
  end

  def to_plain_text(%{"document" => doc}) do
     plain_text = to_plain_text(doc)
     case String.last(plain_text) do
       " " -> String.slice(plain_text, 0..-2)
       # "\n" -> String.slice(plain_text, 0..-2)
        _ -> plain_text
     end
  end
  def to_plain_text(%{"object" => "block", "nodes" => nodes}) do
    [to_plain_text(nodes), " "] |> Enum.join("")
    #[to_plain_text(nodes), "\n"] |> Enum.join("")
  end
  def to_plain_text(%{"object" => "text", "leaves" => leaves}) do
    to_plain_text(leaves)
  end
  def to_plain_text(%{"nodes" => nodes}), do: to_plain_text(nodes)
  def to_plain_text([head|tail]) do
    [to_plain_text(head), to_plain_text(tail)] |> Enum.join("")
  end
  def to_plain_text(%{"text" => text}), do: text
  def to_plain_text(_),  do: ""

end
