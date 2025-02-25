defmodule TbjToPocketWeb.ProxiedAuth do
  @moduledoc """
  Used for webhooks from https://proxiedmail.com where header cannot be set.
  Use origin for veryifing validity.
  """
  import Plug.Conn
  require Logger

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    expected_origin = Application.fetch_env!(:tbj_to_pocket, :expected_origin)
    [%{"address" => origin}] = conn.params["from"]

    if expected_origin == origin do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> halt()
    end
  end
end
