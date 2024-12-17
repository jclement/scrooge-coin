defmodule ScroogeCoin do
  @moduledoc """
  ScroogeCoin is an implementation of the wicked new ScroogeCoin crypto currency used to funder CyberScrooge's sinister actions.

  In a nutshell...

  * This financial system is built up of blocks.
  * Blocks contain transactions
  * A transactions moves ScroogeCoin from one account to another
  * Accounts are ED25519 keypairs (base58 encoded)
     - the public key is the account identifier
     - the sender's private key is used for signing transactions
  * Blocks require proof of work to publish

   > #### Note {: .neutral}
  > ScroogeCoin requires lowercase BASE16 representation for block hashes and transaction signatures. You'll be sad it you use capitals.  i.e.
  >
  > `encode16("Scrooge")` should yield `5363726f6f6765`

  """
end
