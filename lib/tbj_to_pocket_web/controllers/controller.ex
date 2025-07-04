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
         {:ok, %{status: 200}} <- send_url_to_wallabag(id) do
      send_resp(conn, :ok, Jason.encode!(%{success: true, id: id}))
    else
      error ->
        Logger.error("Failed to send url to Wallabag: #{inspect(error)}")
        send_resp(conn, 400, Jason.encode!(%{success: false}))
    end
  end

  # handles webhooks where content is in the request body directly
  def new(conn, %{"html" => binary}) do
    with id = Nanoid.generate(),
         {:ok, true} <- Cachex.put(:articles, id, binary),
         {:ok, %{status: 200}} <- send_url_to_wallabag(id) do
      send_resp(conn, :ok, Jason.encode!(%{success: true, id: id}))
    else
      error ->
        Logger.error("Failed to send url to Wallabag: #{inspect(error)}")
        send_resp(conn, 400, Jason.encode!(%{success: false}))
    end
  end

  defp send_url_to_wallabag(id) do
    url = "#{TbjToPocketWeb.Endpoint.url()}/articles/#{id}"

    retry_func = fn _req, resp ->
      case resp do
        %{status: 200} -> false
        _ -> true
      end
    end

    Req.post("https://app.wallabag.it/api/entries",
      retry: retry_func,
      receive_timeout: 30_000,
      auth: {:bearer, get_access_token()},
      json: %{url: url}
    )
  end

  def get_access_token, do: process_access_token(Cachex.get(:articles, :access_token))

  defp process_access_token({:ok, nil}) do
    wallabag_username = Application.fetch_env!(:tbj_to_pocket, :wallabag_username)
    wallabag_password = Application.fetch_env!(:tbj_to_pocket, :wallabag_password)
    wallabag_client_id = Application.fetch_env!(:tbj_to_pocket, :wallabag_client_id)
    wallabag_client_secret = Application.fetch_env!(:tbj_to_pocket, :wallabag_client_secret)

    params =
      case Cachex.get(:articles, :refresh_token) do
        {:ok, nil} ->
          %{
            grant_type: "password",
            client_id: wallabag_client_id,
            client_secret: wallabag_client_secret,
            username: wallabag_username,
            password: wallabag_password
          }

        {:ok, refresh_token} ->
          %{
            grant_type: "refresh_token",
            client_id: wallabag_client_id,
            client_secret: wallabag_client_secret,
            refresh_token: refresh_token
          }
      end

    %Req.Response{
      status: 200,
      body: %{"access_token" => access_token, "refresh_token" => refresh_token}
    } =
      Req.post!("https://app.wallabag.it/oauth/v2/token",
        receive_timeout: 30_000,
        json: params
      )

    Cachex.put(:articles, :access_token, access_token, expire: :timer.minutes(55))

    Cachex.put(:articles, :refresh_token, refresh_token, expire: :timer.hours(300))

    access_token
  end

  defp process_access_token({:ok, access_token}), do: access_token
end
