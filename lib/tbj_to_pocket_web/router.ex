defmodule TbjToPocketWeb.Router do
  use TbjToPocketWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug TbjToPocketWeb.Auth
  end

  scope "/api", TbjToPocketWeb do
    # pipe_through [:api]
    # pipe_through [:api, :authenticated]

    post "/articles", Controller, :new
  end

  scope "/", TbjToPocketWeb do
    get "/articles/:id", Controller, :show
  end
end
