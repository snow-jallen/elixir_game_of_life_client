defmodule Segment do
  defstruct [:id, :origin, :size, :live_cells, :live_border_cells]

  # returns a segment struct
  def new({id, {x, y}, size}, board) do
    segment = %Segment{id: id, origin: {x,y}, size: size}

    cells =
      board
      |> Enum.filter(fn c ->
        c.x >= x && c.x < (x + size) &&
        c.y >= y && c.y < (x + size)
      end)

    full_border = get_border({x,y}, size)
    live_border_cells =
      Enum.filter(full_border, fn c ->
        Enum.member?(board, c)
      end)

    %Segment{segment | live_cells: cells, live_border_cells: live_border_cells}
  end

  def get_border(origin = {x,y}, size) do
    get_board({x-1, y-1}, size+2) -- get_board(origin, size)
  end

  def get_board({origin_x,origin_y}, size) do
    for x <- origin_x..trunc(origin_x + size - 1),
        y <- origin_y..trunc(origin_y + size - 1) do
      %Cell{x: x, y: y}
    end
  end
end

defmodule Distributed do
  def advance(board) do


  end

  # returns a list of {id, origin, size} tuples
  def split(board) do

  end



  # returns a list of live cells
  def solve_segment(segment) do

  end
end
