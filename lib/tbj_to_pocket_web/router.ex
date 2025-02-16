defmodule TbjToPocketWeb.Router do
  use TbjToPocketWeb, :router

  pipeline :api do
    plug :accepts, ["multipart"]
  end

  pipeline :authenticated do
    plug TbjToPocketWeb.Auth
  end

  scope "/api", TbjToPocketWeb do
    # pipe_through [:api, :authenticated]

    post "/articles", Controller, :new
  end

  scope "/articles", TbjToPocketWeb do
    get "/:id", Controller, :show
  end
end
