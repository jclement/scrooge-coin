defmodule ScroogeCoinWeb.BalancesLive do
  @moduledoc false
  use ScroogeCoinWeb, :live_view
  alias ScroogeCoin.Server
  alias Phoenix.PubSub

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to the PubSub topic
      PubSub.subscribe(ScroogeCoin.PubSub, "new_block")
    end

    {:ok, assign(socket, balances: Server.get_chain().balances)}
  end

  def handle_info({:new_block, _block}, socket) do
    # Add the new record to the list
    {:noreply, assign(socket, balances: Server.get_chain().balances)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6 bg-gray-50 min-h-screen">
      <!-- Chain Info -->
      <div class="mb-6">
        <h1 class="text-2xl font-bold text-gray-800 mb-2">ScroogeChain Balances</h1>
      </div>

      <div class="space-y-6">
        <div class="bg-white shadow rounded-lg p-6">
          
    <!-- Transactions -->
          <h2 class="text-lg font-medium text-gray-800 mb-2">Balances</h2>
          <div class="overflow-x-auto">
            <table class="w-full text-left text-gray-700 border-collapse border border-gray-300 text-xs md:text-sm">
              <thead class="bg-gray-100">
                <tr>
                  <th class="border border-gray-300 px-2 py-0">Address</th>
                  <th class="border border-gray-300 px-2 py-0 text-right">Balance</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  :for={
                    {k, a} <-
                      Enum.reject(Enum.sort_by(@balances, fn {_, a} -> a end, :desc), fn {_, a} ->
                        a == 0
                      end)
                  }
                  class="odd:bg-white even:bg-gray-50"
                >
                  <td class="border border-gray-300 px-2 py-0 font-mono">{k}</td>
                  <td class="border border-gray-300 px-2 py-0 text-right">
                    {ScroogeCoin.Util.with_thousand_separator(a)}
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
