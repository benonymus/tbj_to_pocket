defmodule TbjToPocketWeb.Controller do
  use TbjToPocketWeb, :controller
  require Logger

  defp expire_ms, do: Application.fetch_env!(:tbj_to_pocket, :redis_expire_ms)

  def healthz(conn, _), do: send_resp(conn, 200, "ok")

  def show(conn, %{"id" => id}) do
    case Redix.command(:redix, ["GET", article_key(id)]) do
      {:ok, nil} ->
        send_resp(conn, 404, "not found")

      {:ok, compressed_article} ->
        article = :zlib.uncompress(compressed_article)

        conn
        |> put_resp_header("content-type", "text/html; charset=UTF-8")
        |> send_resp(:ok, article)
    end
  end

  # handles webhooks from file uploads eg.: https://github.com/gildas-lormeau/SingleFile
  def new(conn, %{"data" => data}) do
    with {:ok, binary} <- File.read(data.path),
         compressed_binary = :zlib.compress(binary),
         id = Nanoid.generate(),
         {:ok, _} <-
           Redix.command(:redix, ["SET", article_key(id), compressed_binary, "PX", expire_ms()]),
         {:ok, _job} <- TbjToPocket.ArticeWorker.dispatch(id) do
      send_resp(conn, :ok, Jason.encode!(%{success: true, id: id}))
    else
      error ->
        Logger.error("Failed to send url to Instapaper: #{inspect(error)}")
        send_resp(conn, 400, Jason.encode!(%{success: false}))
    end
  end

  # handles webhooks where content is in the request body directly
  def new(conn, %{"html" => binary}) do
    with compressed_binary = :zlib.compress(binary),
         id = Nanoid.generate(),
         {:ok, _} <-
           Redix.command(:redix, ["SET", article_key(id), compressed_binary, "PX", expire_ms()]),
         {:ok, _job} <- TbjToPocket.ArticeWorker.dispatch(id) do
      send_resp(conn, :ok, Jason.encode!(%{success: true, id: id}))
    else
      error ->
        Logger.error("Failed to send url to Instapaper: #{inspect(error)}")
        send_resp(conn, 400, Jason.encode!(%{success: false}))
    end
  end

  defp article_key(id), do: "articles:#{id}"
end
