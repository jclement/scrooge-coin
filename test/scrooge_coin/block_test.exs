defmodule ScroogeCoin.BlockTest do
  use ExUnit.Case
  alias ScroogeCoin.Block
  alias ScroogeCoin.Transaction

  doctest ScroogeCoin.Block

  test "serialize" do
    b = %Block{
      index: 1,
      timestamp: ~U[2023-12-13 12:00:00Z],
      data: [
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
      ],
      previous_hash: "",
      nonce: 0,
      hash: ""
    }

    assert "{\"index\":1,\"timestamp\":\"2023-12-13T12:00:00Z\",\"data\":[{\"id\":\"1\",\"source\":\"CC1BxRRkb8XuiBELV33AC5xsAGhZaQ1g3pfUXYk88dQc\",\"dest\":\"123\",\"amount\":100,\"comment\":\"hello\",\"sig\":\"d65fdb2ba1ad03f676768c4f4c51f610f118972cb8dea0721182ea3f203ab83ecbc91b50c275c22b01f8fa5e1a9ed9dbe79c9a374d718aec19a90a161b10840b\"}],\"previous_hash\":\"\",\"nonce\":0,\"hash\":\"\"}" ==
             Jason.encode!(b)
  end

  test "hash" do
    b = %Block{
      index: 1,
      timestamp: ~U[2023-12-13 12:00:00Z],
      data: [
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
      ],
      previous_hash: "123",
      nonce: 0
    }

    assert "4d98e5bd624ccb6740cd6d1f8d9396c2" == Block.hash(b)
    assert "9eb557246e49c8466ed2080c11f3ee76" == Block.hash(Map.put(b, :nonce, 1))
  end

  test "valid" do
    assert Block.valid?(%Block{
             index: 1,
             timestamp: ~U[2023-12-13 12:00:00Z],
             data: [
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
             ],
             previous_hash: "123",
             nonce: 0,
             hash: "4d98e5bd624ccb6740cd6d1f8d9396c2"
           })
  end

  test "mine - 1" do
    b =
      Block.mine(
        %Block{
          index: 1,
          timestamp: ~U[2023-12-13 12:00:00Z],
          data: [
            Transaction.sign(
              %Transaction{
                id: "1",
                source: "a642289e61506b5d1f7579377dba415dd9a46e182179b6e79b71c10a7c4c4291",
                dest: "123",
                comment: "hello",
                amount: 100
              },
              "74657374"
            )
          ],
          previous_hash: "123",
          nonce: 0
        },
        1
      )

    assert Block.valid?(b)
    assert String.starts_with?(b.hash, "0")
  end

  test "mine - 3" do
    b =
      Block.mine(
        %Block{
          index: 1,
          timestamp: ~U[2023-12-13 12:00:00Z],
          data: [
            Transaction.sign(
              %Transaction{
                id: "1",
                source: "a642289e61506b5d1f7579377dba415dd9a46e182179b6e79b71c10a7c4c4291",
                dest: "123",
                comment: "hello",
                amount: 100
              },
              "74657374"
            )
          ],
          previous_hash: "123",
          nonce: 0
        },
        3
      )

    assert Block.valid?(b)
    assert String.starts_with?(b.hash, "000")
  end
end
