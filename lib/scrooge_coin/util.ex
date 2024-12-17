defmodule ScroogeCoin.Util do
  @moduledoc false
  def with_thousand_separator(number) when is_integer(number) do
    :io_lib.format("~B", [number])
    |> IO.iodata_to_binary()
    |> String.replace(~r/(?<=\d)(?=(\d{3})+(?!\d))/, ",")
  end
end
