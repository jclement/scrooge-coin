defmodule ScroogeCoin.ChainTest do
  use ExUnit.Case
  alias ScroogeCoin.Transaction
  alias ScroogeCoin.Block
  alias ScroogeCoin.Account
  alias ScroogeCoin.Chain

  test "genesis" do
    {_priv1, pub1} = Account.generate("test1")
    {_priv2, pub2} = Account.generate("test2")

    c = %Chain{difficulty: 0}

    b =
      Block.mine(
        %Block{
          index: 0,
          timestamp: ~U[2001-01-01 12:00:00Z],
          data: [
            %Transaction{dest: pub1, amount: 100},
            %Transaction{dest: pub2, amount: 200}
          ],
          previous_hash: nil
        },
        c.difficulty
      )

    c = Chain.add(c, b)
    assert Map.get(c.balances, pub1) == 100
    assert Map.get(c.balances, pub2) == 200
  end

  test "duplicate genesis block" do
    {_priv1, pub1} = Account.generate("test1")
    {_priv2, pub2} = Account.generate("test2")

    c = %Chain{difficulty: 0}

    b =
      Block.mine(
        %Block{
          index: 0,
          timestamp: ~U[2001-01-01 12:00:00Z],
          data: [
            %Transaction{dest: pub1, amount: 100},
            %Transaction{dest: pub2, amount: 200}
          ],
          previous_hash: nil
        },
        c.difficulty
      )

    c = Chain.add(c, b)
    assert {:error, _} = Chain.add(c, b)
  end

  test "normal blocks" do
    {priv1, pub1} = Account.generate("test1")
    {_priv2, pub2} = Account.generate("test2")
    {_priv3, pub3} = Account.generate("test3")

    c = %Chain{difficulty: 0}

    genesis =
      Block.mine(
        %Block{
          index: 0,
          timestamp: ~U[2001-01-01 12:00:00Z],
          data: [
            %Transaction{dest: pub1, amount: 100},
            %Transaction{dest: pub2, amount: 200}
          ],
          previous_hash: nil
        },
        c.difficulty
      )

    b1 =
      Block.mine(
        %Block{
          index: 1,
          timestamp: ~U[2001-01-01 12:00:00Z],
          data: [
            Transaction.sign(
              %Transaction{source: pub1, dest: pub2, amount: 50, comment: "Eggnog"},
              priv1
            )
          ],
          previous_hash: genesis.hash
        },
        c.difficulty
      )

    b2 =
      Block.mine(
        %Block{
          index: 2,
          timestamp: ~U[2001-01-01 12:00:00Z],
          data: [
            Transaction.sign(
              %Transaction{source: pub1, dest: pub3, amount: 5, comment: "skittles"},
              priv1
            )
          ],
          previous_hash: b1.hash
        },
        c.difficulty
      )

    c =
      c
      |> Chain.add(genesis)
      |> Chain.add(b1)
      |> Chain.add(b2)

    assert Map.get(c.balances, pub1) == 45
    assert Map.get(c.balances, pub2) == 250
    assert Map.get(c.balances, pub3) == 5
    assert 3 == length(c.blocks)
  end

  test "not consecutive" do
    {priv1, pub1} = Account.generate("test1")
    {_priv2, pub2} = Account.generate("test2")

    c = %Chain{difficulty: 0}

    genesis =
      Block.mine(
        %Block{
          index: 0,
          timestamp: ~U[2001-01-01 12:00:00Z],
          data: [
            %Transaction{dest: pub1, amount: 100},
            %Transaction{dest: pub2, amount: 200}
          ],
          previous_hash: nil
        },
        c.difficulty
      )

    b1 =
      Block.mine(
        %Block{
          index: 2,
          timestamp: ~U[2001-01-01 12:00:00Z],
          data: [
            Transaction.sign(
              %Transaction{source: pub1, dest: pub2, amount: 50, comment: "Eggnog"},
              priv1
            )
          ],
          previous_hash: genesis.hash
        },
        c.difficulty
      )

    c = Chain.add(c, genesis)
    assert {:error, _} = Chain.add(c, b1)
  end

  test "bad previous hash" do
    {priv1, pub1} = Account.generate("test1")
    {_priv2, pub2} = Account.generate("test2")

    c = %Chain{difficulty: 0}

    genesis =
      Block.mine(
        %Block{
          index: 0,
          timestamp: ~U[2001-01-01 12:00:00Z],
          data: [
            %Transaction{dest: pub1, amount: 100},
            %Transaction{dest: pub2, amount: 200}
          ],
          previous_hash: nil
        },
        c.difficulty
      )

    b1 =
      Block.mine(
        %Block{
          index: 1,
          timestamp: ~U[2001-01-01 12:00:00Z],
          data: [
            Transaction.sign(
              %Transaction{source: pub1, dest: pub2, amount: 50, comment: "Eggnog"},
              priv1
            )
          ],
          previous_hash: genesis.hash <> "Z"
        },
        c.difficulty
      )

    c = Chain.add(c, genesis)
    assert {:error, _} = Chain.add(c, b1)
  end

  test "overspend" do
    {priv1, pub1} = Account.generate("test1")
    {_priv2, pub2} = Account.generate("test2")

    c = %Chain{difficulty: 0}

    genesis =
      Block.mine(
        %Block{
          index: 0,
          timestamp: ~U[2001-01-01 12:00:00Z],
          data: [
            %Transaction{dest: pub1, amount: 100},
            %Transaction{dest: pub2, amount: 200}
          ],
          previous_hash: nil
        },
        c.difficulty
      )

    b1 =
      Block.mine(
        %Block{
          index: 1,
          timestamp: ~U[2001-01-01 12:00:00Z],
          data: [
            Transaction.sign(
              %Transaction{source: pub1, dest: pub2, amount: 150, comment: "Eggnog"},
              priv1
            )
          ],
          previous_hash: genesis.hash
        },
        c.difficulty
      )

    c = Chain.add(c, genesis)
    assert {:error, "overspend in this block"} = Chain.add(c, b1)
  end

  test "spend from empty account" do
    {priv1, pub1} = Account.generate("test1")
    {_priv2, pub2} = Account.generate("test2")

    c = %Chain{difficulty: 0}

    genesis =
      Block.mine(
        %Block{
          index: 0,
          timestamp: ~U[2001-01-01 12:00:00Z],
          data: [
            %Transaction{dest: pub2, amount: 200}
          ],
          previous_hash: nil
        },
        c.difficulty
      )

    b1 =
      Block.mine(
        %Block{
          index: 1,
          timestamp: ~U[2001-01-01 12:00:00Z],
          data: [
            Transaction.sign(
              %Transaction{source: pub1, dest: pub2, amount: 150, comment: "Eggnog"},
              priv1
            )
          ],
          previous_hash: genesis.hash
        },
        c.difficulty
      )

    c = Chain.add(c, genesis)
    assert {:error, "overspend in this block"} = Chain.add(c, b1)
  end

  test "bad transaction signature" do
    {_priv1, pub1} = Account.generate("test1")
    {priv2, pub2} = Account.generate("test2")

    c = %Chain{difficulty: 0}

    genesis =
      Block.mine(
        %Block{
          index: 0,
          timestamp: ~U[2001-01-01 12:00:00Z],
          data: [
            %Transaction{dest: pub2, amount: 200}
          ],
          previous_hash: nil
        },
        c.difficulty
      )

    b1 =
      Block.mine(
        %Block{
          index: 1,
          timestamp: ~U[2001-01-01 12:00:00Z],
          data: [
            Transaction.sign(
              %Transaction{source: pub1, dest: pub2, amount: 150, comment: "Eggnog"},
              priv2
            )
          ],
          previous_hash: genesis.hash
        },
        c.difficulty
      )

    c = Chain.add(c, genesis)
    assert {:error, "invalid transaction in this block"} = Chain.add(c, b1)
  end
end
