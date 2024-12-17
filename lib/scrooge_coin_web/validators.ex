defmodule ScroogeCoinWeb.FieldValidators do
  @moduledoc false

  def as_integer(x, _) when is_integer(x) and x >= 0, do: {:ok, x}
  def as_integer(_, field), do: {:error, "#{field} must be a positive integer"}

  def as_binary(x, _) when is_binary(x), do: {:ok, x}
  def as_binary(_, field), do: {:error, "#{field} must be a string"}

  def as_address(x, field) when is_binary(x) do
    case B58.decode58(x) do
      {:ok, _} -> {:ok, x}
      {:error, _} -> {:error, "#{field} must be B58 encoded"}
    end
  end

  def as_address(_, field), do: {:error, "#{field} must be a B58 encoded string"}

  def as_base16hash(x, field) when is_binary(x) do
    case Base.decode16(x, case: :lower) do
      {:ok, _} -> {:ok, x}
      :error -> {:error, "#{field} must be base16 encoded (lowercase)"}
    end
  end

  def as_base16hash(_, field), do: {:error, "#{field} must be a base16 encoded string"}

  def as_binary_or_nil(x, _) when is_binary(x) or is_nil(x), do: {:ok, x}
  def as_binary_or_nil(_, field), do: {:error, "#{field} must be a string"}

  def as_date(x, field) when is_binary(x) do
    with {:ok, timestamp, _} <- DateTime.from_iso8601(x) do
      {:ok, timestamp}
    else
      _ -> {:error, "#{field} is not a valid ISO8601 date"}
    end
  end

  def as_date(_, field), do: {:error, "#{field} must be an ISO8601 date as a string"}
end
