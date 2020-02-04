defmodule GameOfLifeClient do
  @moduledoc """
  Start your game of life server by running the following command:

  docker pull snowcollege/gameoflife-server
  docker run -it --rm -p 0.0.0.0:80:80 snowcollege/gameoflife-server

  """
  alias HTTPoison

  def start(), do: start("http://localhost")

  def start(endpoint), do: start(endpoint, "test")

  def start(endpoint, name) do
    IO.puts("********************************************************************")
    IO.puts("****           Starting new Game of Life Client                ****")
    IO.puts("********************************************************************")
    {:ok, guid} = register(endpoint, name)
    IO.inspect guid
    memory_pid = spawn(fn -> remember(0, nil) end)
    IO.inspect(memory_pid, label: "memory_pid")

    heartbeat_pid = spawn(fn -> heartbeat(endpoint, guid, memory_pid, nil) end)
    IO.inspect(heartbeat_pid, label: "heartbeat_pid")
    heartbeat_pid
  end

  def register(endpoint, name) do
    HTTPoison.start
    body = Poison.encode!(%{name: name})
    headers = [{"content-type", "application/json"}]
    case HTTPoison.post!(endpoint<>"/register", body, headers) do
      %HTTPoison.Response{status_code: 500} ->
        register(endpoint, name <> "_1")
      %HTTPoison.Response{status_code: 200, body: body} ->
        body
        |> Poison.decode
        |> IO.inspect(label: "register")
        |> case do
          {:ok, %{"token" => token}} -> {:ok, token}
          _ -> {:error, "Unable to identify token in 200 response"}
        end
      _ ->
        {:error, "Unable to parse response"}
    end
  end

  def heartbeat(endpoint, token, memory_pid, solver_pid) do
    #IO.inspect binding()
    Process.sleep(1_000)

    send(memory_pid, {:get, self()})
    receive do
      {:current_generation, gen} ->
        IO.puts("heartbeat: current generation=#{gen}")
        post_update(endpoint, token, gen, solver_pid, memory_pid)
      {:complete, generations_computed, final_board} ->
        IO.puts("heartbeat: COMPLETED!")
        post_final_update(endpoint, token, generations_computed, final_board)
    end
  end

  def remember(current_generation, final_board) do
    receive do
      {:get, pid} ->
        case final_board do
          nil ->
            IO.puts("mem: Sending {:current_generation, #{current_generation}} because no final_board")
            send(pid, {:current_generation, current_generation})
            remember(current_generation, final_board)
          _ ->
            IO.puts("mem: sending {:complete, #{current_generation}, final_board}")
            send(pid, {:complete, current_generation, final_board})
        end
      {:progress, new_generation} ->
        remember(new_generation, final_board)
      {:complete, generations_computed, final_board} ->
        remember(generations_computed, final_board)
    end
  end

  def post_update(endpoint, token, current_generation, solver_pid, memory_pid) do
    body = Poison.encode!(%{token: token, generationsComputed: current_generation})
    headers = [{"content-type", "application/json"}]

    case HTTPoison.post!(endpoint<>"/update", body, headers) do
      %HTTPoison.Response{status_code: 200, body: body} ->
        body
        |> Poison.decode
        |> IO.inspect(label: "update", limit: 6, pretty: true)
        |> case do
          {:ok, %{"isError" => false, "gameState" => game_state, "generationsToCompute" => generations_to_compute, "seedBoard" => seed_board}} ->
            solver_pid =
              case game_state do
                "InProgress" when solver_pid == nil ->
                  IO.puts("!! Game Started !!  Computing #{generations_to_compute}, starting game")
                  cells =
                    seed_board
                    |> Enum.map(fn c -> %Cell{x: c["x"], y: c["y"]} end)
                  starting_game_state = %Game{memory_pid: memory_pid, generations_to_compute: generations_to_compute, generations_computed: 0, starting_board: cells}
                  spawn(fn -> Game.run(starting_game_state) end)
                _ -> :keep_going
              end
            solver_pid
          {:ok, %{"errorMessage" => error}} -> {:error, error}
        end
    end
    |> IO.inspect(label: "output from post_update! case")
    |> case do
      {:error, error} ->
        IO.puts("reporting error!!!")
        {:error, error}
      :keep_going ->
        IO.puts("keep going w/original solver_pid")
        heartbeat(endpoint, token, memory_pid, solver_pid)
      solver_pid ->
        IO.puts("solver pid returned, calling heartbeat w/solver_pid")
        heartbeat(endpoint, token, memory_pid, solver_pid)
    end
  end

  def post_final_update(endpoint, token, generations_computed, final_board) do
    IO.puts("post_final_update()")

    result_board = Enum.map(final_board, fn c ->
      %{"x" => c.x, "y" => c.y}
    end)

    body = Poison.encode!(%{token: token, generationsComputed: generations_computed, resultBoard: result_board})
    headers = [{"content-type", "application/json"}]

    case HTTPoison.post!(endpoint<>"/update", body, headers) do
      %HTTPoison.Response{status_code: 200, body: body} ->
        body
        |> Poison.decode
        |> IO.inspect(label: "update", limit: 6, pretty: true)
        |> case do
          {:ok, %{"isError" => false, "gameState" => _game_state, "generationsToCompute" => _generations_to_compute, "seedBoard" => _seed_board}} ->
            IO.puts("got back an ok response")
            :ok
          {:ok, %{"errorMessage" => error}} -> {:error, error}
        end
    end
    |> IO.inspect(label: "output from post! case")
    |> case do
      :ok ->
        IO.puts("I think I'm all done!")
      {:error, error} ->
        IO.puts("reporting error!!!")
        {:error, error}
    end
  end
end
