defmodule Game do
  defstruct starting_board: [], generations_to_compute: 0, generations_computed: 0, memory_pid: nil, method: :simple

  def run(starting_board, generations_to_compute) do
    memory_pid = spawn(fn -> GameOfLifeClient.remember(0, nil) end)
    IO.inspect(memory_pid, label: "memory_pid")

    %Game{
      starting_board: starting_board,
      generations_to_compute: generations_to_compute,
      memory_pid: memory_pid
    } |> run()
  end

  def run(%Game{generations_computed: computed, generations_to_compute: to_compute, starting_board: final_board, memory_pid: memory_pid}) when computed == to_compute do
    IO.puts("run(): sending {:complete, #{computed}, final_board}")
    send(memory_pid, {:complete, computed, final_board})
    final_board
  end

  def run(game_state = %Game{}) do
    IO.puts("run(): sending {:progress, #{game_state.generations_computed}} to memory_pid #{inspect game_state.memory_pid}")
    send(game_state.memory_pid, {:progress, game_state.generations_computed})

    new_board =
      case game_state.method do
        :simple ->
          game_state.starting_board
          |> Board.advance()
        :distributed_v1 ->
          game_state.starting_board
          |> Distributed.advance()
      end

    IO.puts("finished generation.")
    %{game_state | starting_board: new_board, generations_computed: game_state.generations_computed + 1}
    |> run()
  end
end
