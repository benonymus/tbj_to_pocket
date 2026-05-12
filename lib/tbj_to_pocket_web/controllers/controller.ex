defmodule TbjToPocketWeb.Controller do
  use TbjToPocketWeb, :controller
  require Logger

  def healthz(conn, _), do: send_resp(conn, 200, "ok")

  # handles webhooks from file uploads eg.: https://github.com/gildas-lormeau/SingleFile
  def new(conn, %{"data" => data}) do
    with {:ok, content} <- File.read(data.path),
         {:ok, %{status: 200}} <- send_content_to_instapaper(content) do
      send_resp(conn, :ok, Jason.encode!(%{success: true}))
    else
      error ->
        Logger.error("Failed to send url to Instapaper: #{inspect(error)}")
        send_resp(conn, 400, Jason.encode!(%{success: false}))
    end
  end

  # handles webhooks where content is in the request body directly
  def new(conn, %{"html" => content}) do
    with {:ok, %{status: 200}} <- send_content_to_instapaper(content) do
      send_resp(conn, :ok, Jason.encode!(%{success: true}))
    else
      error ->
        Logger.error("Failed to send url to Instapaper: #{inspect(error)}")
        send_resp(conn, 400, Jason.encode!(%{success: false}))
    end
  end

  def send_content_to_instapaper(content) do
    url = "https://www.instapaper.com/api/1/bookmarks/add"

    creds =
      OAuther.credentials(
        consumer_key: Application.fetch_env!(:tbj_to_pocket, :consumer_id),
        consumer_secret: Application.fetch_env!(:tbj_to_pocket, :consumer_secret),
        token: Application.fetch_env!(:tbj_to_pocket, :oauth_token),
        token_secret: Application.fetch_env!(:tbj_to_pocket, :oauth_secret)
      )

    params =
      OAuther.sign(
        "post",
        url,
        [{"is_private_from_source", "tbj_to_pocket"}, {"content", content}],
        creds
      )

    {header, req_params} = OAuther.header(params)

    retry_func = fn _req, resp ->
      case resp do
        %{status: 200} -> false
        _ -> true
      end
    end

    Req.post(url,
      retry: retry_func,
      receive_timeout: 30_000,
      headers: [header],
      form: req_params
    )
  end
end
