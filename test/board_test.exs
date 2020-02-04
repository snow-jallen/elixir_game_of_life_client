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

    IO.puts("what about the border?")

    assert top_left.border_cells |> Enum.sort == [%Cell{x: 4, y: 4}, %Cell{x: 4, y: 3}, %Cell{x: 4, y: 2}, %Cell{x: 3, y: 2}, %Cell{x: 2, y: 2}] |> Enum.sort
  end
end
