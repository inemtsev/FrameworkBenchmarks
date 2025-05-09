defmodule FrameworkBenchmarks.Handlers.Query do
  @moduledoc """
  handler for the /queries route
  """
  def handle(conn) do
    number_of_queries = FrameworkBenchmarks.Handlers.Helpers.parse_queries(conn, "queries")

    json =
      1..number_of_queries
      |> Enum.map(fn _ ->
        :rand.uniform(10_000)
      end)
      |> Enum.map(
        &Task.async(fn ->
          FrameworkBenchmarks.Repo.get(FrameworkBenchmarks.Models.World, &1)
        end)
      )
      |> Enum.map(&Task.await(&1, :infinity))
      |> Jason.encode_to_iodata!()

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(200, json)
  end
end
