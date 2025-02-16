defmodule TbjToPocketWeb.Router do
  use TbjToPocketWeb, :router

  pipeline :authenticated do
    plug TbjToPocketWeb.Auth
  end

  scope "/api", TbjToPocketWeb do
    pipe_through [:authenticated]

    post "/articles", Controller, :new
  end

  scope "/articles", TbjToPocketWeb do
    get "/:id", Controller, :show
  end
end
