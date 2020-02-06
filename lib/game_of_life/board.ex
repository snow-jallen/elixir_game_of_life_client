defmodule Board do
  defstruct livecells: []

  def advance_distributed(current_board) do
    current_board
    |> IO.inspect(label: "current_board")
    |> split_board()
    |> IO.inspect(label: "segments")
    #|> Enum.take(1)
    |> Enum.map(fn segment ->
      #Task.async(fn ->
        advance_segment(segment)
      #end)
    end)
    #|> Enum.map(&Task.await(&1))
    |> List.flatten
    |> Enum.uniq
    |> IO.inspect(label: "unique result")
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
      Enum.filter(cells, fn c -> c.x == midpoint_x + 1 && c.y >= midpoint_y - 1 end)

    top_right_border_cells =
      Enum.filter(cells, fn c -> c.x == midpoint_x && c.y >= midpoint_y - 1 end)

    bottom_right_border_cells =
      Enum.filter(cells, fn c -> c.x == midpoint_x && c.y <= midpoint_y end)

    bottom_left_border_cells =
      Enum.filter(cells, fn c -> c.x == midpoint_x + 1 && c.y == midpoint_y end)

    [
      %BoardSegment{
        id: :T_L,
        cells: top_left,
        border_cells: top_left_border_cells,
        x_border: midpoint_x + 1,
        y_border: midpoint_y - 1,
        caller: self()
      },
      %BoardSegment{
        id: :T_R,
        cells: top_right,
        border_cells: top_right_border_cells,
        caller: self()
      },
      %BoardSegment{
        id: :B_R,
        cells: bottom_right,
        border_cells: bottom_right_border_cells,
        caller: self()
      },
      %BoardSegment{
        id: :B_L,
        cells: bottom_left,
        border_cells: bottom_left_border_cells,
        caller: self()
      }
    ]
  end

  def advance_segment(segment = %BoardSegment{}) do
    cells_and_border = segment.cells ++ segment.border_cells

    cells_with_neighbors =
      segment.cells
      |> Enum.reduce([], fn cell, acc ->
        [cell | neighbors(cell)] ++ acc
      end)
      |> Enum.concat(segment.border_cells)
      |> Enum.uniq()
      |> Enum.sort()
      |> IO.inspect(label: "all #{segment.id} cells (including border)")

    cells_of_interest =
      cells_with_neighbors
      |> exclude_border_cells(%{x: segment.x_border, y: segment.y_border})
      |> Enum.sort()
      |> IO.inspect(label: "cells_of_interest for #{segment.id}")

    cells_of_interest
    |> Enum.reduce([], fn cell, acc ->
      cell_should_live?(cell, cells_and_border)
      |> IO.inspect(label: "#{segment.id} @ (#{cell.x}, #{cell.y}) should live")
      |> case do
        true -> [cell | acc]
        _ -> acc
      end
    end)
  end

  def exclude_border_cells(cells, %{x: x_border, y: y_border}) do
    cells
    |> Enum.filter(fn c ->
      x_is_ok(c, x_border) && y_is_ok(c, y_border)
    end)
  end

  defp x_is_ok(cell, x_border) do
    case x_border do
      :infinity -> true
      x -> cell.x != x
    end
  end

  defp y_is_ok(cell, y_border) do
    case y_border do
      :infinity -> true
      y -> cell.y != y
    end
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
