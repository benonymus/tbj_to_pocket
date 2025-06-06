defmodule TbjToPocketWeb.Controller do
  use TbjToPocketWeb, :controller
  require Logger

  def show(conn, %{"id" => id}) do
    case Cachex.get(:articles, id) do
      {:ok, nil} ->
        send_resp(conn, 404, "not found")

      {:ok, article} ->
        conn
        |> put_resp_header("content-type", "text/html; charset=UTF-8")
        |> send_resp(:ok, article)
    end
  end

  # handles webhooks from file uploads eg.: https://github.com/gildas-lormeau/SingleFile
  def new(conn, %{"data" => data}) do
    with {:ok, binary} <- File.read(data.path),
         id = Nanoid.generate(),
         {:ok, true} <- Cachex.put(:articles, id, binary),
         {:ok, %{status: 200}} <- send_url_to_pocket(id) do
      send_resp(conn, :ok, Jason.encode!(%{success: true, id: id}))
    else
      error ->
        Logger.error("Failed to send url to Pocket: #{inspect(error)}")
        send_resp(conn, 400, Jason.encode!(%{success: false}))
    end
  end

  # handles webhooks where content is in the request body directly
  def new(conn, %{"html" => binary}) do
    with id = Nanoid.generate(),
         {:ok, true} <- Cachex.put(:articles, id, binary),
         {:ok, %{status: 200}} <- send_url_to_pocket(id) do
      send_resp(conn, :ok, Jason.encode!(%{success: true, id: id}))
    else
      error ->
        Logger.error("Failed to send url to Pocket: #{inspect(error)}")
        send_resp(conn, 400, Jason.encode!(%{success: false}))
    end
  end

  defp send_url_to_pocket(id) do
    consumer_key = Application.fetch_env!(:tbj_to_pocket, :pocket_consumer_key)
    access_token = Application.fetch_env!(:tbj_to_pocket, :pocket_access_token)
    url = "#{TbjToPocketWeb.Endpoint.url()}/articles/#{id}"

    retry_func = fn _req, resp ->
      case resp do
        %{status: 200} -> false
        _ -> true
      end
    end

    Req.post("https://getpocket.com/v3/add",
      retry: retry_func,
      receive_timeout: 30_000,
      json: %{
        consumer_key: consumer_key,
        access_token: access_token,
        url: url
      }
    )
  end
end
