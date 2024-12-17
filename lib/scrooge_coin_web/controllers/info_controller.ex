defmodule ScroogeCoinWeb.InfoController do
  @moduledoc false

  use ScroogeCoinWeb, :controller
  use PhoenixSwagger
  alias ScroogeCoin.Server

  swagger_path :info do
    get("/api/info")
    summary("Get Info")
    description("What's up with this chain?")

    parameters do
    end

    response(200, "Success", Schema.ref(:InfoResponse))
  end

  def info(conn, _params) do
    chain = Server.get_chain()

    conn
    |> json(%{
      height: chain.height,
      difficulty: chain.difficulty,
      previous_hash: hd(chain.blocks).hash
    })
  end

  def swagger_definitions do
    %{
      InfoResponse:
        swagger_schema do
          title("Info Response")
          description("Some details about the chain")

          properties do
            height(:number, "Number of Blocks on this Chain", required: true)
            difficulty(:number, "Current difficulty level", required: true)
            previous_hash(:string, "Previous Hash", required: true)
          end
        end
    }
  end
end
