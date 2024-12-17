defmodule ScroogeCoinWeb.BlockController do
  @moduledoc false

  use ScroogeCoinWeb, :controller
  use PhoenixSwagger
  alias ScroogeCoin.Block
  alias ScroogeCoin.Transaction
  alias ScroogeCoin.Server
  import ScroogeCoinWeb.FieldValidators

  swagger_path :create do
    post("/api/blocks")
    summary("Upload a Block")
    description("Upload a freshly mined block")

    parameters do
      block(:body, Schema.ref(:Block), "The block details", required: true)
    end

    response(201, "Created")
  end

  def create(conn, params) do
    with {:ok, block} <- params_to_block(params),
         {:ok, _} <- Server.add(block) do
      conn
      |> put_status(:created)
      |> text(Application.get_env(:scrooge_coin, :code))
    else
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> text(reason)
    end
  end

  swagger_path :list do
    get("/api/blocks")
    summary("Get Blocks")
    description("Get the entire block chain")

    parameters do
    end

    response(200, "Success", Schema.ref(:ListResponse))
  end

  def list(conn, _params) do
    chain = Server.get_chain()

    conn
    |> json(%{height: chain.height, blocks: chain.blocks})
  end

  def swagger_definitions do
    %{
      ListResponse:
        swagger_schema do
          title("List Response")
          description("List of all the blocks")

          properties do
            height(:number, "Number of Blocks on this Chain", required: true)

            blocks(:array, "List of blocks",
              items: Schema.ref(:Block),
              required: true
            )
          end
        end,
      Block:
        swagger_schema do
          title("Block")
          description("Represents a ScroogeCoin blockchain block")

          properties do
            index(:integer, "Index of the block in the blockchain", required: true)

            timestamp(:string, "Timestamp of block creation in ISO8601 format",
              format: :"date-time",
              required: true
            )

            data(:array, "List of transactions included in the block",
              items: Schema.ref(:Transaction),
              required: true
            )

            previous_hash(:string, "Hash of the previous block", required: true)
            nonce(:integer, "Nonce value used for mining the block", required: true)
            hash(:string, "Hash of the current block", required: true)
          end

          example(%{
            index: 1,
            timestamp: "2024-12-13T10:00:00Z",
            data: [
              %{
                id: "tx1",
                source: "alice_pubkey",
                dest: "bob_pubkey",
                amount: 100,
                comment: "Payment for services",
                sig: "digital_signature"
              }
            ],
            previous_hash: "abc123",
            nonce: 42,
            hash: "xyz789"
          })
        end,
      Transaction:
        swagger_schema do
          title("Transaction")
          description("Represents a single ScroogeCoin transaction")

          properties do
            id(:string, "Transaction UUID", required: true)
            source(:string, "Source account public key", required: true)
            dest(:string, "Destination account public key", required: true)
            amount(:integer, "Transaction amount", required: true)
            comment(:string, "A comment describing the transaction", required: false)

            sig(
              :string,
              "Digital signature of the source account.  <br>`sig = sign(\"{id}-{source}-{dest}-{amount}-{comment}\", sender_private_key)`",
              required: true
            )
          end

          example(%{
            id: "tx1",
            source: "alice_pubkey",
            dest: "bob_pubkey",
            amount: 100,
            comment: "Payment for services",
            sig: "digital_signature"
          })
        end
    }
  end

  def params_to_block(%{
        "index" => index,
        "timestamp" => timestamp,
        "data" => data,
        "previous_hash" => previous_hash,
        "nonce" => nonce,
        "hash" => hash
      }) do
    with {:ok, index} <- as_integer(index, "index"),
         {:ok, previous_hash} <- as_base16hash(previous_hash, "previous_hash"),
         {:ok, hash} <- as_base16hash(hash, "hash"),
         {:ok, nonce} <- as_integer(nonce, "nonce"),
         {:ok, timestamp} <- as_date(timestamp, "timestamp"),
         {:ok, transactions} <- parse_transactions(data) do
      {:ok,
       %Block{
         index: index,
         timestamp: timestamp,
         data: transactions,
         previous_hash: previous_hash,
         nonce: nonce,
         hash: hash
       }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def params_to_block(_), do: {:error, "Invalid block parameters"}

  defp parse_transactions(data) when is_list(data) do
    transactions =
      Enum.map(data, fn
        %{
          "id" => id,
          "source" => source,
          "dest" => dest,
          "amount" => amount,
          "comment" => comment,
          "sig" => sig
        } ->
          with {:ok, amount} <- as_integer(amount, "amount"),
               {:ok, source} <- as_address(source, "source"),
               {:ok, dest} <- as_address(dest, "dest"),
               {:ok, sig} <- as_base16hash(sig, "sig"),
               {:ok, id} <- as_binary(id, "id"),
               {:ok, comment} <- as_binary_or_nil(comment, "comment") do
            %Transaction{
              id: id,
              source: source,
              dest: dest,
              amount: amount,
              comment: comment,
              sig: sig
            }
          else
            {:error, reason} -> {:error, reason}
          end

        _ ->
          {:error, "Invalid transaction"}
      end)

    if Enum.all?(transactions, &match?(%Transaction{}, &1)) do
      {:ok, transactions}
    else
      {:error, "Invalid transaction data"}
    end
  end

  defp parse_transactions(_), do: {:error, "Transaction data must be a list"}
end
