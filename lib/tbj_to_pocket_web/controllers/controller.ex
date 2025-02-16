defmodule TbjToPocketWeb.Controller do
  use TbjToPocketWeb, :controller

  require Logger

  def show(conn, %{"id" => id}) do
    send_resp(conn, :ok, CubDB.get(:cubdb, id, "no content"))
  end

  def new(conn, %{"data" => data}) do
    with {:ok, binary} <- File.read(data.path),
         id = Nanoid.generate(),
         :ok <- CubDB.put(:cubdb, id, binary),
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

    Req.post("https://getpocket.com/v3/add",
      retry: :transient,
      receive_timeout: 30_000,
      json: %{
        consumer_key: consumer_key,
        access_token: access_token,
        url: url
      }
    )
  end
end
