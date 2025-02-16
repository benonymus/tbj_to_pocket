defmodule TbjToPocketWeb.Auth do
  import Plug.Conn
  require Logger

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         auth_token = Application.fetch_env!(:tbj_to_pocket, :auth_token),
         true <- token == auth_token do
      conn
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> halt()
    end
  end
end
