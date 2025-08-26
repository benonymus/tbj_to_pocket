defmodule TbjToPocketWeb.Controller do
  use TbjToPocketWeb, :controller
  require Logger

  def healthz(conn, _), do: send_resp(conn, 200, "ok")

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
         {:ok, %{status: 201}} <- send_url_to_instapaper(id) do
      send_resp(conn, :ok, Jason.encode!(%{success: true, id: id}))
    else
      error ->
        Logger.error("Failed to send url to Instapaper: #{inspect(error)}")
        send_resp(conn, 400, Jason.encode!(%{success: false}))
    end
  end

  # handles webhooks where content is in the request body directly
  def new(conn, %{"html" => binary}) do
    with id = Nanoid.generate(),
         {:ok, true} <- Cachex.put(:articles, id, binary),
         {:ok, %{status: 201}} <- send_url_to_instapaper(id) do
      send_resp(conn, :ok, Jason.encode!(%{success: true, id: id}))
    else
      error ->
        Logger.error("Failed to send url to Instapaper: #{inspect(error)}")
        send_resp(conn, 400, Jason.encode!(%{success: false}))
    end
  end

  defp send_url_to_instapaper(id) do
    url = "#{TbjToPocketWeb.Endpoint.url()}/articles/#{id}"

    retry_func = fn _req, resp ->
      case resp do
        %{status: 201} -> false
        _ -> true
      end
    end

    Req.post("https://www.instapaper.com/api/add",
      retry: retry_func,
      receive_timeout: 30_000,
      auth: {:basic, Application.fetch_env!(:tbj_to_pocket, :userpass)},
      form: [url: url]
    )
  end
end
