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

  test "solve segment bottom left" do
    segment = %Segment{
      id: "1",
      live_border_cells: [%Cell{x: 2, y: 3}, %Cell{x: 3, y: 2}, %Cell{x: 3, y: 3}],
      live_cells: [%Cell{x: 2, y: 2}],
      origin: {0, 0},
      size: 3
    }
    expected_cells = [%Cell{x: 2, y: 2}]

    actual_cells =
      segment
      |> Segment.solve_segment()
      |> Enum.sort()

    assert actual_cells == expected_cells
  end

  test "exclude outside cells" do
    segment = %Segment{
      id: "1",
      live_border_cells: [%Cell{x: 2, y: 3}, %Cell{x: 3, y: 2}, %Cell{x: 3, y: 3}],
      live_cells: [],
      origin: {0, 0},
      size: 3
    }

    cells_and_neighbors = [%Cell{x: 2, y: 3}, %Cell{x: 3, y: 2}, %Cell{x: 3, y: 3}, %Cell{x: 2, y: 2}]

    actual_cells_of_interest = Segment.exclude_outside_cells(cells_and_neighbors, segment)
    expected_cells_of_interest = [%Cell{x: 2, y: 2}]

    assert actual_cells_of_interest == expected_cells_of_interest
  end

  test "solve segment top left" do
    segment = %Segment{
      id: "TL",
      live_border_cells: [
        %Cell{x: 2, y: 2},
        %Cell{x: 3, y: 2},
        %Cell{x: 4, y: 2},
        %Cell{x: 4, y: 3},
        %Cell{x: 4, y: 4}
      ],
      live_cells: [
        %Cell{x: 2, y: 4},
        %Cell{x: 3, y: 4},
        %Cell{x: 2, y: 3},
        %Cell{x: 3, y: 3}
      ],
      origin: {1, 3},
      size: 3
    }
    expected_cells = [%Cell{x: 1, y: 3},%Cell{x: 2, y: 4}, %Cell{x: 3, y: 5}]

    actual_cells =
      segment
      |> Segment.solve_segment()
      |> Enum.sort()

    assert actual_cells == expected_cells
  end

  test "solve segment top right" do
    segment = %Segment{
      id: "TR",
      live_border_cells: [
        %Cell{x: 3, y: 2},
        %Cell{x: 3, y: 3},
        %Cell{x: 3, y: 4},
        %Cell{x: 4, y: 2}
      ],
      live_cells: [%Cell{x: 4, y: 4}, %Cell{x: 4, y: 3}],
      origin: {4, 3},
      size: 8
    }
    expected_cells = [%Cell{x: 4, y: 4}, %Cell{x: 5, y: 3}]
    actual_cells =
      segment
      |> Segment.solve_segment()
      |> Enum.sort

    assert actual_cells == expected_cells
  end

  test "solve segment bottom right" do
    segment = %Segment{
      id: "BR",
      live_border_cells: [%Cell{x: 3, y: 2}, %Cell{x: 3, y: 3}, %Cell{x: 4, y: 3}],
      live_cells: [%Cell{x: 4, y: 2}],
      origin: {4, 0},
      size: 3
    }
    expected_cells = [%Cell{x: 4, y: 2}]
    actual_cells =
      segment
      |> Segment.solve_segment()
      |> Enum.sort

    assert actual_cells == expected_cells
  end

  test "split board" do
    starting_board = [
      %Cell{x: 2, y: 4}, %Cell{x: 3, y: 4}, %Cell{x: 4, y: 4},
      %Cell{x: 2, y: 3}, %Cell{x: 3, y: 3}, %Cell{x: 4, y: 3},
      %Cell{x: 2, y: 2}, %Cell{x: 3, y: 2}, %Cell{x: 4, y: 2},
    ]

    actual_split = Distributed.split(starting_board)

    expected_split = [{"0-0", {2, 2}, 2}, {"0-1", {2, 4}, 2}, {"1-0", {4, 2}, 2}, {"1-1", {4, 4}, 2}]

    assert actual_split == expected_split
  end

  test "advance board" do
    starting_board = [
      %Cell{x: 2, y: 4}, %Cell{x: 3, y: 4}, %Cell{x: 4, y: 4},
      %Cell{x: 2, y: 3}, %Cell{x: 3, y: 3}, %Cell{x: 4, y: 3},
      %Cell{x: 2, y: 2}, %Cell{x: 3, y: 2}, %Cell{x: 4, y: 2},
    ]

    actual_board = Distributed.advance(starting_board)

    expected_board = [
      %Cell{x: 1, y: 3},
      %Cell{x: 2, y: 2}, %Cell{x: 2, y: 4},
      %Cell{x: 3, y: 1}, %Cell{x: 3, y: 5},
      %Cell{x: 4, y: 2}, %Cell{x: 4, y: 4},
      %Cell{x: 5, y: 3},
    ]

    assert actual_board |> Enum.sort == expected_board |> Enum.sort
  end
end
