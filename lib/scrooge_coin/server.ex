defmodule ScroogeCoin.Server do
  @moduledoc false

  use GenServer
  alias Phoenix.PubSub
  alias ScroogeCoin.Block
  alias ScroogeCoin.Chain
  alias ScroogeCoin.Transaction

  ## API

  # Starts the GenServer
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # Add a transaction
  def add(%Block{} = block) do
    GenServer.call(__MODULE__, {:add_block, block})
  end

  def add!(%Block{} = block) do
    {:ok, block} = GenServer.call(__MODULE__, {:add_block, block})
    block
  end

  def get_chain() do
    GenServer.call(__MODULE__, :get_chain)
  end

  ## GenServer Callbacks

  @impl true
  def init(_) do
    file_path = Application.get_env(:scrooge_coin, :chain_file)

    if !File.exists?(file_path) do
      # bootstrap the chain by tossing some sweet scroogebucks at
      # the founders!
      difficulty = Application.get_env(:scrooge_coin, :difficulty)

      data =
        [
          Block.mine(
            %Block{
              index: 0,
              timestamp: DateTime.utc_now(),
              data: [
                %Transaction{
                  id: "GENESIS-1",
                  dest: "1eHesskxTf3J23zZCxNobsyaswKtAi84ozfkLyhvbso",
                  amount: 100_000_000_000,
                  comment: "Allocation to Scrooge"
                },
                %Transaction{
                  id: "GENESIS-2",
                  dest: "6dLuH1CkteqaUFGdnvAtGTE9yPfyAZikLzYacmq5tNhz",
                  amount: 50_000_000_000,
                  comment: "Allocation to Fred"
                }
              ]
            },
            difficulty
          )
        ]
        |> Enum.reduce(%Chain{difficulty: difficulty}, fn block, acc -> Chain.add(acc, block) end)
        |> :erlang.term_to_binary()

      IO.puts("Data file #{file_path} not found.  Bootstrapping")
      File.write!(file_path, data)
    end

    chain =
      file_path
      |> File.read!()
      |> :erlang.binary_to_term()

    {:ok, chain}
  end

  @impl true
  def handle_call({:add_block, block}, _from, chain) do
    case Chain.add(chain, block) do
      {:error, reason} ->
        {:reply, {:error, reason}, chain}

      updated_chain ->
        file_path = Application.get_env(:scrooge_coin, :chain_file)
        File.write!(file_path, :erlang.term_to_binary(updated_chain))
        PubSub.broadcast(ScroogeCoin.PubSub, "new_block", {:new_block, block})

        {:reply, {:ok, block}, updated_chain}
    end
  end

  def handle_call(:get_chain, _from, chain) do
    {:reply, chain, chain}
  end
end
