defmodule TbjToPocketWeb.Router do
  use TbjToPocketWeb, :router

  pipeline :authenticated do
    plug TbjToPocketWeb.Auth
  end

  pipeline :proxied_authenticated do
    plug TbjToPocketWeb.ProxiedAuth
  end

  scope "/api", TbjToPocketWeb do
    pipe_through [:authenticated]
    post "/articles", Controller, :new
  end

  scope "/api", TbjToPocketWeb do
    pipe_through [:proxied_authenticated]
    post "/proxied-articles", Controller, :new
  end

  scope "/articles", TbjToPocketWeb do
    get "/:id", Controller, :show
  end
end
