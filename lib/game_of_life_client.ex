defmodule GameOfLifeClient do
  def game do
    {:ok, guid} = register("http://localhost")
  end

  def register(endpoint) do
    HTTPoison.start
    body = Poison.encode!(%{name: "class"})
    headers = [{"Content-type", "application/json"}]
    HTTPoison.post!(endpoint<>"/register", body, headers)
  end
end
