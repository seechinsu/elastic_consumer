defmodule ElasticConsumer do
  require Logger
  alias GenRMQ.Message
  alias Elastix.{Document, Index}

  @behaviour GenRMQ.Consumer
  @elastic_url Elastix.config(:elastic_url)

  ##### Consumer API #####
  def start_link() do
    GenRMQ.Consumer.start_link(__MODULE__, name: __MODULE__)
  end

  def ack(%Message{attributes: %{delivery_tag: tag}} = message) do
    Logger.debug("Message successfully processed. Tag: #{tag}")
    GenRMQ.Consumer.ack(message)
  end

  def reject(%Message{attributes: %{delivery_tag: tag}} = message, requeue \\ true) do
    Logger.info("Rejecting message, tag: #{tag}, requeue: #{requeue}")
    GenRMQ.Consumer.reject(message, requeue)
  end

  ##### Consumer callbacks #####
  def init() do
    elastic_create_index()

    [
      queue: "tweets",
      exchange: "twitter",
      routing_key: "",
      prefetch_count: "10",
      uri: System.get_env("AMQP_URL")
    ]
  end

  defp elastic_create_index do
    Index.create(@elastic_url, "twitter", %{})
  end

  def handle_message(%Message{} = message) do
    message = Jason.decode!(~s(#{message.payload}))
    tweet = message["tweet"]

    {:ok, response} =
      @elastic_url
      |> Document.index_new("twitter", "tweet", %{message: tweet})

    {:ok, indexed_doc} = Document.get(@elastic_url, "twitter", "tweet", response.body["_id"])

    IO.inspect(indexed_doc.body["_source"]["message"])

    ack(message)
  rescue
    exception ->
      Logger.error(Exception.format(:error, exception, System.stacktrace()))
      IO.puts("Error converting #{message.payload} to integer")
      reject(message, false)
  end

  def consumer_tag() do
    {:ok, hostname} = :inet.gethostname()
    "#{hostname}-example-consumer"
  end
end
