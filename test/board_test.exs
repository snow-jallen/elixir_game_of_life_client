defmodule BoardTest do
  use ExUnit.Case

  test "split board" do
    starting_board = [
      %Cell{x: 2, y: 4}, %Cell{x: 3, y: 4}, %Cell{x: 4, y: 4},
      %Cell{x: 2, y: 3}, %Cell{x: 3, y: 3}, %Cell{x: 4, y: 3},
      %Cell{x: 2, y: 2}, %Cell{x: 3, y: 2}, %Cell{x: 4, y: 2},
    ]

    [top_left = %BoardSegment{id: :T_L} | _rest] = Board.split_board(starting_board)

    assert top_left.cells |> Enum.sort == [ %Cell{x: 2, y: 4}, %Cell{x: 3, y: 4}, %Cell{x: 2, y: 3}, %Cell{x: 3, y: 3}] |> Enum.sort
    assert top_left.border_cells |> Enum.sort == [%Cell{x: 4, y: 4}, %Cell{x: 4, y: 3}, %Cell{x: 4, y: 2}, %Cell{x: 3, y: 2}, %Cell{x: 2, y: 2}] |> Enum.sort
  end

  test "exclude_border_cells" do
    cells = [%Cell{x: 1, y: 1}, %Cell{x: 1, y: 50}, %Cell{x: 2, y: 1}, %Cell{x: 2, y: 2}]

    actual = Board.exclude_border_cells(cells, %{x: 2, y: :infinity})
    expected = [%Cell{x: 1, y: 1}, %Cell{x: 1, y: 50}]

    assert expected == actual
  end

  test "compare result" do
    starting_board = [
      %Cell{x: 2, y: 4}, %Cell{x: 3, y: 4}, %Cell{x: 4, y: 4},
      %Cell{x: 2, y: 3}, %Cell{x: 3, y: 3}, %Cell{x: 4, y: 3},
      %Cell{x: 2, y: 2}, %Cell{x: 3, y: 2}, %Cell{x: 4, y: 2},
    ]

    expected = Board.advance(starting_board) |> Enum.sort
    actual = Board.advance_distributed(starting_board) |> Enum.sort

    assert expected == actual

    expected = Enum.reduce(1..9, starting_board, fn x, board -> Board.advance(board) end) |> Enum.sort
    actual = Enum.reduce(1..9, starting_board, fn x, board ->
      IO.puts("******************************")
      IO.puts("*** Doing generation #{x}")
      IO.puts("******************************")
      Board.advance_distributed(board)
      |> Enum.sort()
      |> IO.inspect(label: "Generation #{x}")
    end) |> Enum.sort

    assert expected == actual
  end

  test "7th generation" do
    # x = 9, y = 9, rule = B3/S23
    # 4bo$4bo$4bo2$3o3b3o2$4bo$4bo$4bo!
    gen7 =  [
      %Cell{x: -1, y: 3},
      %Cell{x: 0, y: 3},
      %Cell{x: 1, y: 3},
      %Cell{x: 3, y: -1},
      %Cell{x: 3, y: 0},
      %Cell{x: 3, y: 1},
      %Cell{x: 3, y: 5},
      %Cell{x: 3, y: 6},
      %Cell{x: 3, y: 7},
      %Cell{x: 5, y: 3},
      %Cell{x: 6, y: 3},
      %Cell{x: 7, y: 3}
    ]

    # expected gen8
    # x = 7, y = 7, rule = B3/S23
    # 2b3o2$o5bo$o5bo$o5bo2$2b3o!
    expected_gen8 = [
      %Cell{x: 0, y: 2},
      %Cell{x: 0, y: 3},
      %Cell{x: 0, y: 4},
      %Cell{x: 2, y: 0},
      %Cell{x: 2, y: 6},
      %Cell{x: 3, y: 0},
      %Cell{x: 3, y: 6},
      %Cell{x: 4, y: 0},
      %Cell{x: 4, y: 6},
      %Cell{x: 6, y: 2},
      %Cell{x: 6, y: 3},
      %Cell{x: 6, y: 4}
    ]

    actual_gen8 = Board.advance_distributed(gen7) |> Enum.sort()

    assert expected_gen8 == actual_gen8

  end
end
