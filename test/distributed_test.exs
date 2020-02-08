defmodule DistributedTest do
  use ExUnit.Case

  test "make_segment simple" do
    starting_board = [
      %Cell{x: 2, y: 4}, %Cell{x: 3, y: 4}, %Cell{x: 4, y: 4},
      %Cell{x: 2, y: 3}, %Cell{x: 3, y: 3}, %Cell{x: 4, y: 3},
      %Cell{x: 2, y: 2}, %Cell{x: 3, y: 2}, %Cell{x: 4, y: 2},
    ]
    actual_segment = Segment.new({"1", {0,0}, 3}, starting_board)

    expected_segment = %Segment{
      id: "1",
      origin: {0,0},
      size: 3,
      live_cells: [%Cell{x: 2, y: 2}],
      live_border_cells: [%Cell{x: 2, y: 3}, %Cell{x: 3, y: 2}, %Cell{x: 3, y: 3}]
    }

    assert actual_segment == expected_segment
  end

  test "get border" do
    actual_border = Segment.get_border({0,0}, 3)
    expected_border = [%Cell{x: -1, y: -1},%Cell{x: -1, y: 0},%Cell{x: -1, y: 1},%Cell{x: -1, y: 2},%Cell{x: -1, y: 3},
    %Cell{x: 0, y: 3},%Cell{x: 1, y: 3},%Cell{x: 2, y: 3}, %Cell{x: 3, y: 3}, %Cell{x: 3, y: 2}, %Cell{x: 3, y: 1}, %Cell{x: 3, y: 0},
    %Cell{x: 3, y: -1}, %Cell{x: 2, y: -1}, %Cell{x: 1, y: -1}, %Cell{x: 0, y: -1}]

    assert actual_border |> Enum.sort == expected_border |> Enum.sort
  end
end
