defmodule GameOfLifeClient do
  @moduledoc """
  Start your game of life server by running the following command:

  docker pull snowcollege/gameoflife-server
  docker run -it --rm -p 0.0.0.0:80:80 snowcollege/gameoflife-server

  """
  alias HTTPoison

  @endpoint "http://localhost"

  def start do
    {:ok, guid} = register(@endpoint, "test")
    IO.inspect guid
    memory_pid = spawn(fn -> remember(0) end)
    IO.inspect(memory_pid, label: "memory_pid")

    solver_pid = spawn(fn -> solve(memory_pid) end)
    IO.inspect(solver_pid, label: "solver_pid")

    has_started = false
    heartbeat_pid = spawn(fn -> heartbeat(@endpoint, guid, memory_pid, solver_pid, has_started) end)
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

  def heartbeat(endpoint, token, memory_pid, solver_pid, has_started) do
    Process.sleep(5_000)

    send(memory_pid, {:get, self()})
    current_generation =
      receive do
        {:current_generation, gen} -> gen
      end

    body = Poison.encode!(%{token: token, generationsComputed: current_generation})
    headers = [{"content-type", "application/json"}]
    case HTTPoison.post!(endpoint<>"/update", body, headers) do
      %HTTPoison.Response{status_code: 200, body: body} ->
        body
        |> Poison.decode
        |> IO.inspect(label: "update")
        |> case do
          {:ok, %{"isError" => false, "gameState" => game_state, "generationsToCompute" => generations_to_compute, "seedBoard" => seed_board}} ->
            case game_state do
              "InProgress" when has_started == false ->
                solver_pid = spawn(fn -> Game.run(seed_board, generations_to_compute, memory_pid) end)
                has_started = true
              "InProgress" when has_started == true ->
                send(solver_pid, %{board: seed_board, generations: generations_to_compute})
              _ -> nil
            end
          {:ok, %{"errorMessage" => error}} -> {:error, error}
        end
    end

    heartbeat(endpoint, token, memory_pid, solver_pid, has_started)
  end

  def remember(current_generation) do
    receive do
      {:get, pid} ->
        send(pid, {:current_generation, current_generation})
        remember(current_generation)
      {:set, new_generation} ->
        remember(new_generation)
    end
  end

  def solve(mem_pid) do
    receive do
      %{board: seed_board, generations: generations_to_compute} ->
        Game.run(seed_board, generations_to_compute, mem_pid)
    end
  end
end
