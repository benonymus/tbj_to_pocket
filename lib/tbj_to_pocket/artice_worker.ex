defmodule TbjToPocket.ArticeWorker do
  alias BullMQ.Job

  def dispatch(article_id) do
    BullMQ.Queue.add("dispatch", "add_article", %{article_id: article_id},
      connection: :bullmq_redix,
      attempts: 10,
      remove_on_complete: true,
      remove_on_fail: %{count: 10},
      backoff: %{type: "exponential", delay: 2000}
    )
  end

  def process(%Job{name: "add_article", data: %{"article_id" => article_id}}) do
    url = "https://www.instapaper.com/api/1/bookmarks/add"

    creds =
      OAuther.credentials(
        consumer_key: Application.fetch_env!(:tbj_to_pocket, :consumer_id),
        consumer_secret: Application.fetch_env!(:tbj_to_pocket, :consumer_secret),
        token: Application.fetch_env!(:tbj_to_pocket, :oauth_token),
        token_secret: Application.fetch_env!(:tbj_to_pocket, :oauth_secret)
      )

    params =
      OAuther.sign(
        "post",
        url,
        [
          {"url", "#{TbjToPocketWeb.Endpoint.url()}/articles/#{article_id}"},
          {"resolve_final_url", 0}
        ],
        creds
      )

    {header, req_params} = OAuther.header(params)

    case Req.post(url,
           receive_timeout: 25_000,
           headers: [header],
           form: req_params
         ) do
      {:ok, %{status: 200}} -> :ok
      error -> {:error, inspect(error)}
    end
  end

  def process(%Job{name: name}) do
    {:error, "Unknown job type: #{name}"}
  end
end
