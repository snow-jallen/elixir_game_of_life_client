defmodule Board do
  defstruct livecells: []

  def advance_distributed(current_board) do
    current_board
    |> split_board()
  end

  def split_board(cells) do
    max_y =
      cells
      |> Enum.map(& &1.y)
      |> Enum.max()

    max_x =
      cells
      |> Enum.map(& &1.x)
      |> Enum.max()

    min_y =
      cells
      |> Enum.map(& &1.y)
      |> Enum.min()

    min_x =
      cells
      |> Enum.map(& &1.x)
      |> Enum.min()

    midpoint_x = (max_x - min_x) / 2 + min_x
    midpoint_y = (max_y - min_y) / 2 + min_y

    IO.puts("midpoint_x = #{midpoint_x}, midpoint_y = #{midpoint_y}")

    top_left = Enum.filter(cells, fn c -> c.x <= midpoint_x && c.y >= midpoint_y end)
    top_right = Enum.filter(cells, fn c -> c.x > midpoint_x && c.y >= midpoint_y end)
    bottom_right = Enum.filter(cells, fn c -> c.x > midpoint_x && c.y < midpoint_y end)
    bottom_left = Enum.filter(cells, fn c -> c.x <= midpoint_x && c.y < midpoint_y end)

    top_left_border_cells =
      Enum.filter(cells, fn c -> c.x == midpoint_x + 1 || c.y == midpoint_y - 1 end)

    top_right_border_cells =
      Enum.filter(cells, fn c -> c.x == midpoint_x || c.y == midpoint_y - 1 end)

    bottom_right_border_cells =
      Enum.filter(cells, fn c -> c.x == midpoint_x || c.y == midpoint_y end)

    bottom_left_border_cells =
      Enum.filter(cells, fn c -> c.x == midpoint_x + 1 || c.y == midpoint_y end)

    [
      %BoardSegment{
        id: :top_left,
        cells: top_left,
        border_cells: top_left_border_cells,
        caller: self()
      },
      %BoardSegment{
        id: :top_right,
        cells: top_right,
        border_cells: top_right_border_cells,
        caller: self()
      },
      %BoardSegment{
        id: :bottom_right,
        cells: bottom_right,
        border_cells: bottom_right_border_cells,
        caller: self()
      },
      %BoardSegment{
        id: :bottom_left,
        cells: bottom_left,
        border_cells: bottom_left_border_cells,
        caller: self()
      }
    ]
  end

  def advance(current_board) do
    current_board
    |> Enum.reduce([], fn cell, acc ->
      [cell | neighbors(cell)] ++ acc
    end)
    |> Enum.uniq()
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
    |> Enum.count()
  end

  def neighbors(%Cell{} = cell) do
    [
      %Cell{x: cell.x - 1, y: cell.y + 1},
      %Cell{x: cell.x - 1, y: cell.y + 0},
      %Cell{x: cell.x - 1, y: cell.y - 1},
      %Cell{x: cell.x + 0, y: cell.y + 1},
      %Cell{x: cell.x + 0, y: cell.y - 1},
      %Cell{x: cell.x + 1, y: cell.y + 1},
      %Cell{x: cell.x + 1, y: cell.y + 0},
      %Cell{x: cell.x + 1, y: cell.y - 1}
    ]
  end
end
