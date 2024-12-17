defmodule ScroogeCoin.Transaction do
  @moduledoc """
  Represents a ScroogeCoin transaction: a transfer of funds from the source to the dest
  account (identified by their respective public keys).  The message must be signed by
  the source account's private key.  See `account.ex` and the `hash` function balow for
  details on signing.
  """
  alias ScroogeCoin.Account

  @derive {Jason.Encoder, only: [:id, :source, :dest, :amount, :comment, :sig]}
  defstruct [:id, :source, :dest, :amount, :comment, :sig]

  @doc """
  Verify that the signature on a transaction is valid

  ```
  iex> ScroogeCoin.Transaction.valid?(%ScroogeCoin.Transaction{
  ...>   id: "1",
  ...>   source: "CC1BxRRkb8XuiBELV33AC5xsAGhZaQ1g3pfUXYk88dQc",
  ...>   dest: "123",
  ...>   comment: "hello",
  ...>   amount: 100,
  ...>   sig: "d65fdb2ba1ad03f676768c4f4c51f610f118972cb8dea0721182ea3f203ab83ecbc91b50c275c22b01f8fa5e1a9ed9dbe79c9a374d718aec19a90a161b10840b"
  ...> })
  true
  ```
  """
  def valid?(transaction),
    do: Account.verify?(serialize(transaction), transaction.sig, transaction.source)

  @doc """
  Sign a transaction with a given private key (which hopefully matches the sender public key)

  ```
  iex> ScroogeCoin.Transaction.sign(%ScroogeCoin.Transaction{
  ...>   id: "1",
  ...>   source: "CC1BxRRkb8XuiBELV33AC5xsAGhZaQ1g3pfUXYk88dQc",
  ...>   dest: "123",
  ...>   comment: "hello",
  ...>   amount: 100
  ...> }, "3yZe7d")
  %ScroogeCoin.Transaction{
     id: "1",
     source: "CC1BxRRkb8XuiBELV33AC5xsAGhZaQ1g3pfUXYk88dQc",
     dest: "123",
     comment: "hello",
     amount: 100,
     sig: "d65fdb2ba1ad03f676768c4f4c51f610f118972cb8dea0721182ea3f203ab83ecbc91b50c275c22b01f8fa5e1a9ed9dbe79c9a374d718aec19a90a161b10840b"
  }
  ```
  """
  def sign(transaction, private_key),
    do: Map.put(transaction, :sig, Account.sign(serialize(transaction), private_key))

  @doc """
  Generate a text representation of a transaction for signing purposes.

  In the form:
  "{id}-{source}-{dest}-{amount}-{comment}"

  ```
  iex> ScroogeCoin.Transaction.serialize(%ScroogeCoin.Transaction{
  ...>   id: "1",
  ...>   source: "CC1BxRRkb8XuiBELV33AC5xsAGhZaQ1g3pfUXYk88dQc",
  ...>   dest: "123",
  ...>   comment: "hello",
  ...>   amount: 100,
  ...>   sig: "d65fdb2ba1ad03f676768c4f4c51f610f118972cb8dea0721182ea3f203ab83ecbc91b50c275c22b01f8fa5e1a9ed9dbe79c9a374d718aec19a90a161b10840b"
  ...> })
  "1-CC1BxRRkb8XuiBELV33AC5xsAGhZaQ1g3pfUXYk88dQc-123-100-hello"
  ```
  """

  def serialize(%{id: id, source: source, dest: dest, amount: amount, comment: comment}) do
    "#{id}-#{source}-#{dest}-#{amount}-#{comment}"
  end
end
