defmodule ScroogeCoin.AccountTest do
  use ExUnit.Case
  alias ScroogeCoin.Account

  doctest ScroogeCoin.Account

  test "generate" do
    assert {_, _} = Account.generate()
  end

  test "generate deterministic" do
    assert {"H2eFXbcCgqEwGhTrBXneTBM1n3vv4SXbLopaYsFKtGHX",
            "5jcwWoFmccMQ756mZXwnPVMdWZ4VrFo7xzggGiuGtnG1"} =
             Account.generate("test")
  end

  test "sign" do
    assert "4f55397d120079acadf8cd4dd519b21efcd3cc44753f106ed2731049c8c216182e680c91b27372586a7b7c8a9b238bd6f5dbd11d5c6affc8cc3fd49d9149d106" =
             Account.sign("hello", "H2eFXbcCgqEwGhTrBXneTBM1n3vv4SXbLopaYsFKtGHX")
  end

  test "verify?" do
    assert Account.verify?(
             "hello",
             "4f55397d120079acadf8cd4dd519b21efcd3cc44753f106ed2731049c8c216182e680c91b27372586a7b7c8a9b238bd6f5dbd11d5c6affc8cc3fd49d9149d106",
             "5jcwWoFmccMQ756mZXwnPVMdWZ4VrFo7xzggGiuGtnG1"
           )
  end
end
