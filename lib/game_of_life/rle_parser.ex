defmodule RleParser do
  def parse(rle_string) do
    [_x, x, _y, y, _rule, rule | lines] =
      rle_string
      |> String.split([",", "=", "\n", "$", "!"], trim: true)

    result = %{
      x: x |> String.trim |> String.to_integer,
      y: y |> String.trim |> String.to_integer,
      rule: rule |> String.trim,
      lines: lines
    }

    cells = []
    row = result.y
    {_row, cells} = lines
      |> Enum.reduce({row, cells}, fn line, {row, cells} ->
        {cells, row} = parse_line(line, row, cells)
        {row - 1, cells}
      end)
    cells
  end

  def parse_line(line, row, cells) do
    {cells, row, _col} = line_to_parts(line)
      |> Enum.reduce({cells, row, 1}, fn part, {cells, row, col} ->
        case ends_in_o_or_b(part) do
          true ->
            %{cells: cells, col: new_col} = add_cells(part, row, col, cells)
            {cells, row, new_col}
          false ->
            # The row will naturally be decreased by 1 so we skip 1 less row
            rows_to_skip = String.to_integer(part) - 1
            {cells, row - rows_to_skip, col}
        end
      end)
    {cells, row}
  end

  def ends_in_o_or_b(part) do
    String.contains?(part, "o") || String.contains?(part, "b")
  end

  def line_to_parts(line) do
    Regex.split(~r{(\d*[ob])}, line, trim: true, include_captures: true)
    |> Enum.map(fn
      "o" -> "1o"
      "b" -> "1b"
      other -> other
    end)
  end

  def add_cells(command, row, col, cells) do
    case Integer.parse(command) do
      {count, "o"} ->
        case count do
          0 ->
            %{cells: cells, col: col}
          _ ->
            cells = [%Cell{x: col, y: row} | cells]
            add_cells("#{count-1}o", row, col+1, cells)
        end
      {count, "b"} ->
        %{cells: cells, col: col + count}
    end
  end

  def dump(cells) do
    IO.inspect(cells, label: "before shift_negative")
    cells = shift_negative(cells)
    IO.inspect(cells, label: "after shift_negative")

    max_x =
      cells
      |> Enum.map(&(&1.x))
      |> Enum.max

    max_y =
      cells
      |> Enum.map(&(&1.y))
      |> Enum.max

    cells
    |> Enum.sort(&(&1.y >= &2.y))
    |> Enum.group_by(&(&1.y), &(&1.x))
    |> Enum.sort
    |> Enum.reverse
    |> fill_in_empty_rows()
    |> Enum.reduce("x = #{max_x}, y = #{max_y}, rule = B3/S23\n", fn {_row, cells}, rle ->
      rle <> encode(Enum.sort(cells))
      end)
    |> replace_last_dollar_with_bang()
    |> consolidate_multiple_dollar_signs()
  end

  def consolidate_multiple_dollar_signs(rle) do
    rle
    |> String.replace(~r/\$*/, fn match ->
      case String.length(match) do
        0 -> ""
        1 -> "$"
        n -> "#{n}$"
        end
    end)
  end

  def fill_in_empty_rows(rows = [_first = {starting_row, _} | _rest]) do

    {_, result} = rows
      |> Enum.reduce({starting_row,[]}, fn r = {row_num, _cells}, {last_row, result} ->
        case last_row - row_num do
          0 -> {row_num, [r | result]}
          1 -> {row_num, [r | result]}
          n ->
            new_rows =
              (n-1)..1
              |> Enum.map(fn x ->
                new_row = last_row - x
                {new_row, []}
              end)
            {last_row - n, [r] ++ new_rows ++ result}
        end
      end)

    result
    |> Enum.reverse
  end

  def shift_negative(cells) do
    #find min x, min y, add to get to 1
    delta_x =
      cells
      |> Enum.map(&(&1.x))
      |> Enum.min
      |> case do
        neg_x when neg_x < 0 -> neg_x * -1
        0 -> 0
        pos_x -> (pos_x - 1) * -1
      end

    delta_y =
      cells
      |> Enum.map(&(&1.y))
      |> Enum.min
      |> case do
        neg_y when neg_y < 0 -> neg_y * -1
        0 -> 0
        pos_y -> (pos_y - 1) * -1
      end

    IO.puts("delta_x=#{delta_x}; delta_y=#{delta_y}")

    cells
    |> Enum.reduce([], fn c, acc ->
      new_cell = %Cell{x: c.x + delta_x, y: c.y + delta_y}
      IO.puts("moving from #{inspect c} to #{inspect new_cell}")
      [new_cell] ++ acc
    end)
  end

  def replace_last_dollar_with_bang(rle) do
    Regex.replace(~r/\$$/, rle, "!")
  end

  # Note: Michael Ries' solution is _much_ shorter.
  # Study his @ https://gist.github.com/mmmries/9ec5dfecaf8f6b5048ed2c98305d3335

  def encode([]), do: "$"
  def encode([1]), do: "o$"

  def encode([first]) when first > 1 do
    case first - 1 do
      1 -> "bo$"
      n -> "#{n}bo$"
    end
  end

  def encode(row=[first|_rest]) when first > 1 do
    case first - 1 do
      1 -> do_encode("b", row)
      n -> do_encode("#{n}b", row)
    end
  end

  def encode(row=[1|_rest]) do
    do_encode("", row)
  end

  defp do_encode(acc, row=[first,next|_rest]) when first + 1 == next do
    num = count_sequence(row)
    remaining = Enum.drop(row, num)

    blanks =
      case remaining do
        [] -> ""
        _ ->
          num_blanks = Enum.at(row, num) - Enum.at(row, num-1) - 1
          case num_blanks do
            1 -> "b"
            n -> "#{n}b"
          end
      end

    acc <> "#{num}o" <> blanks
    |> do_encode(remaining)
  end

  defp do_encode(acc, _row=[first,next|rest]) do
    blanks =
      case next - first - 1 do
        1 -> "b"
        n -> "#{n}b"
      end
    acc <> "o" <> blanks
    |> do_encode([next|rest])
  end

  defp do_encode(acc, [_last]) do
    acc <> "o$"
  end

  defp do_encode(acc, []), do: acc <> "$"

  def count_sequence(_row=[first,next|rest]) when first + 1 == next do
    do_count_sequence([next | rest], 2)
  end

  def count_sequence([first,last]) when first + 1 == last, do: 2
  def count_sequence([]), do: 0
  def count_sequence(_), do: 1

  defp do_count_sequence([first,next], acc) when first + 1 == next do
    acc + 1
  end

  defp do_count_sequence(_row=[first,next|rest], acc) when first + 1 == next do
    do_count_sequence([next | rest], acc+1)
  end

  defp do_count_sequence(_, acc), do: acc
end
