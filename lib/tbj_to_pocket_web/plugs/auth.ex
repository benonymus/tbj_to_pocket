defmodule TbjToPocketWeb.Auth do
  import Plug.Conn
  require Logger

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    conn
    |> get_req_header("authorization")
    |> auth()
    |> case do
      true ->
        conn

      _ ->
        conn
        |> put_status(:unauthorized)
        |> halt()
    end
  end

  defp auth(["Bearer " <> token]),
    do: token == Application.fetch_env!(:tbj_to_pocket, :auth_token)
end
