defmodule Game do
  def run(final_board, generations_to_compute, generations_computed , memory_pid) when generations_computed == generations_to_compute do
    IO.puts("run(): sending {:complete, #{generations_computed}, final_board}")
    send(memory_pid, {:complete, generations_computed, final_board})
    final_board
  end

  def run(starting_board, generations_to_compute, generations_computed, memory_pid) do
    IO.puts("run(): sending {:progress, #{generations_computed}} to memory_pid #{inspect memory_pid}")
    send(memory_pid, {:progress, generations_computed})
    starting_board
    |> Board.advance()
    |> run(generations_to_compute, generations_computed + 1, memory_pid)
  end
end
