defmodule ScroogeCoinWeb.HomeLive do
  @moduledoc false
  use ScroogeCoinWeb, :live_view
  alias ScroogeCoin.Server
  alias Phoenix.PubSub

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to the PubSub topic
      PubSub.subscribe(ScroogeCoin.PubSub, "new_block")
    end

    chain = Server.get_chain()

    {:ok,
     socket
     |> assign(blocks: chain.blocks)
     |> assign(height: chain.height)
     |> assign(difficulty: chain.difficulty)}
  end

  def handle_params(%{"a" => address}, _uri, socket) do
    {:noreply, assign(socket, address: address)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, address: nil)}
  end

  def handle_info({:new_block, block}, socket) do
    # Add the new record to the list
    {:noreply,
     socket
     |> update(:blocks, fn blocks -> [block | blocks] end)
     |> update(:height, fn height -> height + 1 end)}
  end

  defp transaction_matches(_transaction, nil), do: true

  defp transaction_matches(transaction, address) do
    transaction.dest == address || transaction.source == address
  end

  defp block_matches(block, address) do
    Enum.any?(block.data, &transaction_matches(&1, address))
  end

  def render(assigns) do
    ~H"""
    <div class="p-6 bg-gray-50 min-h-screen">
      <!-- Chain Info -->
      <div class="mb-6">
        <h1 class="text-2xl font-bold text-gray-800 mb-2">ScroogeChain Explorer</h1>
        <div class="grid grid-cols-2 gap-4 bg-white shadow rounded-lg p-4">
          <div>
            <span class="block text-sm font-medium text-gray-500">Current Difficulty</span>
            <span class="text-lg font-semibold text-gray-800">{@difficulty}</span>
          </div>
          <div>
            <span class="block text-sm font-medium text-gray-500">Block Height</span>
            <span class="text-lg font-semibold text-gray-800">{@height}</span>
          </div>
        </div>
      </div>

      <div :if={@address}>
        <div class="bg-yellow-100 mb-4 border-l-4 border-yellow-500 text-yellow-700 p-4 rounded-lg flex items-center justify-between">
          <div>
            <p class="text-sm font-medium">
              ⚠️ You are seeing filtered results. All transactions including account <span class="font-semibold">{@address}</span>.
            </p>
          </div>
          <.link patch={~p"/"}>
            <button class="ml-4 bg-yellow-500 hover:bg-yellow-600 text-white text-sm font-medium py-1 px-3 rounded focus:outline-none focus:ring-2 focus:ring-yellow-400 focus:ring-offset-1">
              Clear Filter
            </button>
          </.link>
        </div>
      </div>
      
    <!-- Blocks -->
      <div class="space-y-6">
        <div
          :for={block <- Enum.filter(@blocks, &block_matches(&1, @address))}
          class="bg-white shadow rounded-lg p-6 overflow-x-auto"
        >
          <!-- Block Info -->
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4 border-b pb-4 mb-4">
            <div>
              <span class="block text-xs sm:text-sm font-medium text-gray-500">Block Index</span>
              <span class="text-xs sm:text-lg font-semibold text-gray-800">{block.index}</span>
            </div>
            <div>
              <span class="block text-xs sm:text-sm font-medium text-gray-500">Timestamp</span>
              <span class="text-xs sm:text-lg font-semibold text-gray-800">{block.timestamp}</span>
            </div>
            <div>
              <span class="block text-xs sm:text-sm font-medium text-gray-500">Block Hash</span>
              <span class="text-xs sm:text-lg font-semibold text-gray-800">{block.hash}</span>
            </div>
          </div>
          
    <!-- Transactions -->
          <h2 class="text-lg font-medium text-gray-800 mb-2">Transactions</h2>
          <div class="overflow-x-auto">
            <table class="w-full text-left text-gray-700 border-collapse border border-gray-300 text-[6pt] md:text-sm">
              <thead class="bg-gray-100">
                <tr>
                  <th class="border border-gray-300 px-2 py-0">ID</th>
                  <th class="border border-gray-300 px-2 py-0">Source</th>
                  <th class="border border-gray-300 px-2 py-0">Destination</th>
                  <th class="border border-gray-300 px-2 py-0 text-right">Amount</th>
                  <th class="border border-gray-300 px-2 py-0">Comment</th>
                  <th class="border border-gray-300 px-2 py-0">Signature</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  :for={t <- Enum.filter(block.data, &transaction_matches(&1, @address))}
                  class="odd:bg-white even:bg-gray-50"
                >
                  <td class="border border-gray-300 px-2 py-0">{t.id}</td>
                  <td
                    class="border border-gray-300 px-2 py-0 font-mono truncate max-w-xs"
                    title={t.source}
                  >
                    <.link patch={"?a=#{t.source}"} class="text-blue-500 hover:underline">
                      {t.source}
                    </.link>
                  </td>
                  <td
                    class="border border-gray-300 px-2 py-0 font-mono truncate max-w-xs"
                    title={t.dest}
                  >
                    <.link patch={"?a=#{t.dest}"} class="text-blue-500 hover:underline">
                      {t.dest}
                    </.link>
                  </td>
                  <td class="border border-gray-300 px-2 py-0 text-right">
                    {ScroogeCoin.Util.with_thousand_separator(t.amount)}
                  </td>
                  <td class="border border-gray-300 px-2 py-0">{t.comment}</td>
                  <td
                    class="border border-gray-300 px-2 py-0 font-mono truncate max-w-xs"
                    title={t.sig}
                  >
                    {t.sig}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
