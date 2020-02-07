defmodule BoardSegment do
  defstruct [:id, :x_border, :y_border, :cells, :live_border_cells, :all_border_cells, :caller]
end
