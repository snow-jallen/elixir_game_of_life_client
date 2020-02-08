defmodule Segment do
  defstruct [:id, :origin, :size, :live_cells, :live_border_cells]

  # returns a segment struct
  def new({id, {x, y}, size}, board) do
    segment = %Segment{id: id, origin: {x,y}, size: size}

    cells =
      board
      |> Enum.filter(&is_in_segment(&1,{x,y},size))

    full_border = get_border({x,y}, size)
    live_border_cells =
      Enum.filter(full_border, fn c ->
        Enum.member?(board, c)
      end)

    %Segment{segment | live_cells: cells, live_border_cells: live_border_cells}
  end

  def is_in_segment(c = %Cell{}, _origin = {x,y}, size) do
    (c.x >= x && c.x < (x + size) && c.y >= y && c.y < (y + size))
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

  def exclude_outside_cells(cells, segment = %Segment{}) do
    cells
    |> Enum.filter(fn c -> is_in_segment(c, segment.origin, segment.size) end)
  end

  # returns a list of live cells
  def solve_segment(segment = %Segment{live_border_cells: live_border, live_cells: cells}) do
    cells_and_border = cells ++ live_border

    _cells_and_neighbors =
      cells_and_border
      |> Enum.reduce([], fn cell, acc ->
        [cell | Board.neighbors(cell)] ++ acc
      end)
      |> Enum.uniq()
      |> exclude_outside_cells(segment)
      |> Enum.sort()
      |> Enum.reduce([], fn cell, acc ->
        Board.cell_should_live?(cell, cells_and_border)
        #|> IO.inspect(label: "#{segment.id} @ (#{cell.x}, #{cell.y}) should live")
        |> case do
          true -> [cell | acc]
          _ -> acc
        end
      end)
  end
end

defmodule Distributed do
  def advance(board) do
    board
    |> split #returns [{id, origin, size}]
    |> Enum.map(fn segment_definition ->
      Segment.new(segment_definition, board)
    end) # returns [%Segment{}]
    |> Enum.map(fn segment ->
      Task.async(fn ->
        Segment.solve_segment(segment)
      end)
    end)
    |> Enum.map(&Task.await(&1))
    |> List.flatten
    |> Enum.uniq
  end

  # returns a list of {id, origin, size} tuples
  def split(board) do
    {{min_x, min_y}, {max_x, max_y}} = bounds = get_bounds(board)

    num_segments = determine_times_to_cut(bounds)

    width = max_x - min_x + 1
    height = max_y - min_y + 1

    segment_width = width / num_segments
    segment_height = height / num_segments

    segment_size = trunc(max(segment_width, segment_height))

    segment_size =
      case rem(segment_size, 2) do
        0 -> segment_size
        _ -> segment_size + 1
      end

    for x <- 0..(num_segments - 1), y <- 0..(num_segments - 1) do
      {"#{x}-#{y}", {min_x + (x * segment_size), min_y + (y * segment_size)}, segment_size}
    end
  end

  def determine_times_to_cut(_), do: 2

  def get_bounds(cells) do
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

    {{min_x, min_y}, {max_x, max_y}}
  end

end
