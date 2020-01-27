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
    heartbeat_pid = spawn(fn -> heartbeat(@endpoint, guid) end)
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

  def heartbeat(endpoint, token) do
    Process.sleep(1_000)

    body = Poison.encode!(%{token: token})
    headers = [{"content-type", "application/json"}]
    case HTTPoison.post!(endpoint<>"/update", body, headers) do
      %HTTPoison.Response{status_code: 200, body: body} ->
        body
        |> Poison.decode
        |> IO.inspect(label: "update")
        |> case do
          {:ok, %{"isError" => false}} -> "it worked!"
          {:ok, %{"errorMessage" => error}} -> {:error, error}
        end
    end

    heartbeat(endpoint, token)
  end
end
