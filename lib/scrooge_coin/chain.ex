defmodule ScroogeCoin.Chain do
  @moduledoc """
  This module represents an instance of the ScroogeCoin Chain and consists of a chain of blocks, as well
  as some helpful things like running balances by account.
  """
  alias ScroogeCoin.Block
  alias ScroogeCoin.Transaction

  defstruct difficulty: 1, height: 0, blocks: [], balances: %{}

  @doc """
  Add a block to the BlockChain.

  Block index 0 is the special genesis block.  It poofs coins into existance without
  requiring a source address / signature.  All other blocks must have valid transactions.

  * Blocks must be contiguous by index. (i.e. if the latest block is index 7, the next block must be 8)
  * Blocks must have a timestamp but, due to timetravel, they don't have to be in chronological order
  * A block is invalid if it contains invalid transactions (bad signature, overspend)
  * A block must have a valid signature
  * A block must have a hash that meets the current difficulty 
    (i.e. the hash starts with {difficulty} zeros)
  """

  # special implementation for the genesis block (only if the chain is empty)
  def add(%{blocks: []} = chain, %Block{index: 0, data: data} = block) do
    chain
    |> Map.update(:balances, %{}, fn balances ->
      Enum.reduce(data, balances, fn %Transaction{dest: dest, amount: amount}, acc ->
        Map.update(acc, dest, amount, fn v -> v + amount end)
      end)
    end)
    |> Map.update(:blocks, [], fn blocks -> [block | blocks] end)
    |> Map.put(:height, 1)
  end

  # can't add the genesis block twice
  def add(_, %Block{index: 0}), do: {:error, "Genesis block already exists"}

  def add(chain, block) do
    cond do
      !Block.valid?(block) ->
        {:error, "bogus block signature"}

      !String.starts_with?(Block.hash(block), String.duplicate("0", chain.difficulty)) ->
        {:error, "block hash does not meet difficulty"}

      hd(chain.blocks).index + 1 != block.index ->
        {:error, "not the next block"}

      hd(chain.blocks).hash != block.previous_hash ->
        {:error, "invalid previous hash"}

      !Enum.all?(block.data, &Transaction.valid?(&1)) ->
        {:error, "invalid transaction in this block"}

      true ->
        chain = update_chain(chain, block)

        if Enum.any?(chain.balances, fn {_, v} -> v < 0 end) do
          {:error, "overspend in this block"}
        else
          chain
        end
    end
  end

  defp update_chain(chain, block) do
    chain
    |> Map.update(:balances, %{}, fn balances ->
      Enum.reduce(block.data, balances, fn %Transaction{
                                             source: source,
                                             dest: dest,
                                             amount: amount
                                           },
                                           acc ->
        acc
        |> Map.update(dest, amount, fn v -> v + amount end)
        |> Map.update(source, -amount, fn v -> v - amount end)
      end)
    end)
    |> Map.update(:blocks, [], fn blocks -> [block | blocks] end)
    |> Map.update(:height, 0, fn height -> height + 1 end)
  end
end
