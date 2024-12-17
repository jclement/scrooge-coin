defmodule ScroogeCoin.Block do
  @moduledoc """
  A ScroogeCoin block is a bundle of valid (signed) transactions.

  Blocks include the hash of the block that comes before (you know... a block chain).

  Blocks are have a require a proof of work calculation based on the chain difficulty.
  """
  @derive {Jason.Encoder, only: [:index, :timestamp, :data, :previous_hash, :nonce, :hash]}
  defstruct [:index, :timestamp, :data, :previous_hash, :nonce, :hash]

  @doc """
  Verify that the Block Hash is valid for the contents of the Block
  """
  def valid?(block), do: hash(block) == block.hash

  @doc """
  Mine a block with a given difficulty target.  This means find a nonce value
  that causes the computed block hash to start with N zeros (where N is the
  chain difficulty)
  """
  def mine(block, difficulty),
    do: find_nonce(Map.put(block, :nonce, 0), String.duplicate("0", difficulty))

  defp find_nonce(block, target) do
    block = Map.put(block, :hash, hash(block))

    if String.starts_with?(block.hash, target) do
      block
    else
      find_nonce(Map.put(block, :nonce, block.nonce + 1), target)
    end
  end

  @doc """
  Find the hash of the Block.

  ```
  iex> ScroogeCoin.Block.hash(%ScroogeCoin.Block{
  ...>   index: 1,
  ...>   timestamp: ~U[2023-12-13 12:00:00Z],
  ...>   data: [
  ...>     Transaction.sign(
  ...>       %Transaction{
  ...>         id: "1",
  ...>         source: "CC1BxRRkb8XuiBELV33AC5xsAGhZaQ1g3pfUXYk88dQc",
  ...>         dest: "123",
  ...>         comment: "hello",
  ...>         amount: 100
  ...>       },
  ...>       "3yZe7d"
  ...>     )
  ...>   ],
  ...>   previous_hash: "123",
  ...>   nonce: 0
  ...>   })
  "4d98e5bd624ccb6740cd6d1f8d9396c2"
  ```

  > #### Note {: .neutral}
  > ScroogeCoin requires that lowercase BASE16 representation.  i.e.
  >
  > `encode16("Scrooge")` should yield `5363726f6f6765`

  """
  def hash(block) do
    :crypto.hash(:md5, serialize(block)) |> Base.encode16(case: :lower)
  end

  @doc """
  Serialize a block for hashing. This gets a little icky.

  The first line, is the block header

  ```text
  {index}//{timestamp:ISO8601}//{previous_hash}//{nonce}
  ```

  Then, each transaction is added on a separate line in the form...

  ```text
  {id}-{source}-{dest}-{amount}-{comment}-{sig}
  ```

  For example:

  ```
  iex> ScroogeCoin.Block.serialize(%ScroogeCoin.Block{
  ...>   index: 1,
  ...>   timestamp: ~U[2023-12-13 12:00:00Z],
  ...>   data: [
  ...>     Transaction.sign(
  ...>       %Transaction{
  ...>         id: "1",
  ...>         source: "CC1BxRRkb8XuiBELV33AC5xsAGhZaQ1g3pfUXYk88dQc",
  ...>         dest: "123",
  ...>         comment: "hello",
  ...>         amount: 100
  ...>       },
  ...>       "3yZe7d"
  ...>     )
  ...>   ],
  ...>   previous_hash: "123",
  ...>   nonce: 0,
  ...>   hash: "4d98e5bd624ccb6740cd6d1f8d9396c2"
  ...>   }) <> "\\n"
  \"\"\"
  1//2023-12-13T12:00:00Z//123//0
  1-CC1BxRRkb8XuiBELV33AC5xsAGhZaQ1g3pfUXYk88dQc-123-100-hello-d65fdb2ba1ad03f676768c4f4c51f610f118972cb8dea0721182ea3f203ab83ecbc91b50c275c22b01f8fa5e1a9ed9dbe79c9a374d718aec19a90a161b10840b
  \"\"\"
  ```

  Lines are separated by `\n` only (Scrooge doesn't do Windows).
  """
  def serialize(%{
        index: index,
        timestamp: timestamp,
        previous_hash: previous_hash,
        nonce: nonce,
        data: data
      }) do
    (["#{index}//#{timestamp |> DateTime.to_iso8601()}//#{previous_hash}//#{nonce}"] ++
       Enum.map(data, fn %{
                           id: id,
                           source: source,
                           dest: dest,
                           amount: amount,
                           comment: comment,
                           sig: sig
                         } ->
         "#{id}-#{source}-#{dest}-#{amount}-#{comment}-#{sig}"
       end))
    |> Enum.join("\n")
  end
end
