defmodule BoardTest do
  use ExUnit.Case

  test "split board" do
    starting_board = [
      %Cell{x: 2, y: 4}, %Cell{x: 3, y: 4}, %Cell{x: 4, y: 4},
      %Cell{x: 2, y: 3}, %Cell{x: 3, y: 3}, %Cell{x: 4, y: 3},
      %Cell{x: 2, y: 2}, %Cell{x: 3, y: 2}, %Cell{x: 4, y: 2},
    ]

    [top_left = %BoardSegment{id: :top_left} | _rest] = Board.split_board(starting_board)

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
      #%Cell{x: 50, y: 50}
    ]

    expected = Board.advance(starting_board) |> Enum.sort
    actual = Board.advance_distributed(starting_board) |> Enum.sort

    assert expected == actual
  end
end
