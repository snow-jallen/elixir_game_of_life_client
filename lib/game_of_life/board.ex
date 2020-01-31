defmodule Board do
  defstruct livecells: []

  def advance(current_board) do
    current_board
    |> Enum.reduce([], fn cell, acc ->
      [cell | neighbors(cell)] ++ acc
    end)
    |> Enum.uniq
    |> Enum.reduce([], fn cell, acc ->
      case cell_should_live?(cell, current_board) do
        true -> [cell | acc]
        _ -> acc
      end
    end)
  end

  def cell_should_live?(cell, board) do
    case neighbor_count(cell, board) do
      n when n < 2 -> false
      n when n == 2 -> Enum.member?(board, cell)
      n when n == 3 -> true
      n when n > 3 -> false
    end
  end

  def neighbor_count(cell, board) do
    neighbors(cell)
    |> Enum.filter(fn neighbor -> Enum.member?(board, neighbor) end)
    |> Enum.count
  end

  def neighbors(%Cell{} = cell) do
    [
      %Cell{x: cell.x-1, y: cell.y+1},
      %Cell{x: cell.x-1, y: cell.y+0},
      %Cell{x: cell.x-1, y: cell.y-1},
      %Cell{x: cell.x+0, y: cell.y+1},
      %Cell{x: cell.x+0, y: cell.y-1},
      %Cell{x: cell.x+1, y: cell.y+1},
      %Cell{x: cell.x+1, y: cell.y+0},
      %Cell{x: cell.x+1, y: cell.y-1}
    ]
  end
end
