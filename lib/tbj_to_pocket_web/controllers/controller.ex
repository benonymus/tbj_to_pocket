defmodule TbjToPocketWeb.Controller do
  use TbjToPocketWeb, :controller

  def show(conn, %{"id" => _id}) do
    send_resp(conn, :ok, CubDB.get(:cubdb, :test))
  end

  def new(conn, %{"data" => data}) do
    {:ok, binary} = File.read(data.path)

    CubDB.put(:cubdb, :test, binary)

    send_resp(conn, :ok, "success: true")
  end
end
