defmodule TbjToPocketWeb.Router do
  use TbjToPocketWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", TbjToPocketWeb do
    pipe_through :api
  end
end
