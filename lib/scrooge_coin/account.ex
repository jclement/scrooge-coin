defmodule ScroogeCoin.Account do
  @moduledoc """
  Functions for managing accounts.  Accounts are simply an ED25519 keypair.  The account identifier is
  the public key ([base58 encoded](https://learnmeabitcoin.com/technical/keys/base58/)), and the sender's private key is used to sign transactions.  You can't spend
  money if you don't have the private key!

  Note that we support both randomly generated account identifiers, and deterministic identifiers based
  on a secret.  The later are much weaker.
  """

  @doc """
  Generate a new random {private, public} keypair
  """
  def generate() do
    {private, public} = Ed25519.generate_key_pair()
    {B58.encode58(private), B58.encode58(public)}
  end

  @doc """
  Generate a new deterministic {private, public} keypair

  Note that the first 32-bytes of the sha512 hash of the secret are used as the seed material when generating the ED25519 private key.

  > #### Note {: .neutral}
  > To streamline integration with ScroogeBank account holders, we use the ScroogeBank 6-digit account numbers to generate the private key for most accounts vs. completely random keys.

  ```elixir
  iex> ScroogeCoin.Account.generate("hello")
  {"BTnrheTVgrUk8zgc2xnVj5uYph9chdsdg9kBNxYjY7ti", "44ovaiVvQUcEdcZddi1WxJEN8d6w4jvdcG1h7MDC9FHq"}
  ```

  ## Python example:
  ```python
  import nacl.signing
  import hashlib
  import base58

  def generate_ed25519_keypair(secret: str):
      secret_bytes = secret.encode('utf-8')
      seed = hashlib.sha512(secret_bytes).digest()[:32]
      signing_key = nacl.signing.SigningKey(seed)
      verify_key = signing_key.verify_key
      private_key_b58 = base58.b58encode(signing_key.encode()).decode('utf-8')
      public_key_b58 = base58.b58encode(verify_key.encode()).decode('utf-8')
      return private_key_b58, public_key_b58

  private_key, public_key = generate_ed25519_keypair("test")

  print("Private Key (Base58):", private_key)
  print("Public Key (Base58):", public_key)
  ```

  Note in the above example `BTnrheTVgrUk8zgc2xnVj5uYph9chdsdg9kBNxYjY7ti` is the private key that would be used for signing operations.
  """
  def generate(secret) do
    secret = binary_part(:crypto.hash(:sha512, secret), 0, 32)
    {private, public} = Ed25519.generate_key_pair(secret)
    {B58.encode58(private), B58.encode58(public)}
  end

  @doc """
  Generate a new vanity {private, public} keypair starting with a prefix.  Make sure to use characters that are actuall in the B58 charset!
  """
  def generate_vanity(prefix) do
    num_workers = System.schedulers_online()

    Task.async_stream(
      1..num_workers,
      fn _ -> find_matching_key(prefix) end,
      max_concurrency: num_workers,
      timeout: :infinity
    )
    # Filter successful results
    |> Stream.filter(&match?({:ok, {_private, _public}}, &1))
    # Take the first match
    |> Enum.take(1)
    |> hd()
    # Extract the result tuple
    |> elem(1)
  end

  defp find_matching_key(prefix) do
    {private, public} = Ed25519.generate_key_pair()
    encoded_public = B58.encode58(public)

    if String.starts_with?(encoded_public, prefix) do
      {B58.encode58(private), encoded_public}
    else
      find_matching_key(prefix)
    end
  end

  @doc """
  Sign a message with an account private key and return signature base16 encoded

  ```
  iex> ScroogeCoin.Account.sign("hello", "H2eFXbcCgqEwGhTrBXneTBM1n3vv4SXbLopaYsFKtGHX")
  "4f55397d120079acadf8cd4dd519b21efcd3cc44753f106ed2731049c8c216182e680c91b27372586a7b7c8a9b238bd6f5dbd11d5c6affc8cc3fd49d9149d106"
  ```

  ## Python example:
  ```python
  import nacl.signing
  import hashlib
  import base58

  def sign(message, private_key_b58):
      seed = base58.b58decode(private_key_b58)
      signing_key = nacl.signing.SigningKey(seed)
      signed_message = signing_key.sign(message.encode('utf-8'))
      return signed_message.signature.hex().lower()

  # Example usage:
  signature = sign("hello", "H2eFXbcCgqEwGhTrBXneTBM1n3vv4SXbLopaYsFKtGHX")
  print("Signature:", signature)

  ```
  """
  def sign(message, private_key) do
    {:ok, private_key} = B58.decode58(private_key)

    message
    |> Ed25519.signature(private_key)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Verify a message/signature pair with a given key.  Returns `true` for a valid signature.

  * Note that public_key must be base58 encoded
  * Note that signature must be base16(lowercase) encoded

  ```
  iex> message = "hello"
  iex> public_key = "CC1BxRRkb8XuiBELV33AC5xsAGhZaQ1g3pfUXYk88dQc"
  iex> sig = "de436a3800c92736ee4fb3830b782945a906bc0eefbac727f4de1bf7ebfda2755864ca3f105b709faf9d4c8acf066b8092eedd249ce406f11e312109f89e5206"
  iex> Account.verify?(message, sig, public_key)
  true
  iex> Account.verify?("goodbye", sig, public_key)
  false
  ```
  """
  def verify?(message, signature, public_key) do
    {:ok, public_key} = B58.decode58(public_key)
    {:ok, signature} = Base.decode16(signature, case: :lower)
    Ed25519.valid_signature?(signature, message, public_key)
  end
end
