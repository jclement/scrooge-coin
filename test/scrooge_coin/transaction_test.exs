defmodule ScroogeCoin.TransactionTest do
  use ExUnit.Case
  alias ScroogeCoin.Transaction

  doctest ScroogeCoin.Transaction

  test "sign" do
    assert %{
             sig:
               "d65fdb2ba1ad03f676768c4f4c51f610f118972cb8dea0721182ea3f203ab83ecbc91b50c275c22b01f8fa5e1a9ed9dbe79c9a374d718aec19a90a161b10840b"
           } =
             Transaction.sign(
               %Transaction{
                 id: "1",
                 source: "CC1BxRRkb8XuiBELV33AC5xsAGhZaQ1g3pfUXYk88dQc",
                 dest: "123",
                 comment: "hello",
                 amount: 100
               },
               "3yZe7d"
             )
  end

  test "signature_valid?" do
    assert Transaction.valid?(%Transaction{
             id: "1",
             source: "CC1BxRRkb8XuiBELV33AC5xsAGhZaQ1g3pfUXYk88dQc",
             dest: "123",
             comment: "hello",
             amount: 100,
             sig:
               "d65fdb2ba1ad03f676768c4f4c51f610f118972cb8dea0721182ea3f203ab83ecbc91b50c275c22b01f8fa5e1a9ed9dbe79c9a374d718aec19a90a161b10840b"
           })

    assert !Transaction.valid?(%Transaction{
             id: "1",
             source: "CC1BxRRkb8XuiBELV33AC5xsAGhZaQ1g3pfUXYk88dQc",
             dest: "123",
             comment: "hello",
             amount: 101,
             sig:
               "b65fdb2ba1ad03f676768c4f4c51f610f118972cb8dea0721182ea3f203ab83ecbc91b50c275c22b01f8fa5e1a9ed9dbe79c9a374d718aec19a90a161b10840b"
           })
  end
end
