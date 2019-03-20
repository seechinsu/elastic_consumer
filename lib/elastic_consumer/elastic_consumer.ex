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
      queue: "create_user",
      exchange: "seraph",
      routing_key: "",
      prefetch_count: "10",
      uri: System.get_env("AMQP_URL")
    ]
  end

  defp elastic_create_index do
    Index.create(@elastic_url, "seraph", %{})
  end

  def handle_message(%Message{} = message) do
    payload = Jason.decode!(~s(#{message.payload}))

    {:ok, response} =
      @elastic_url
      |> Document.index_new("seraph", "user", %{message: payload})

    # IO.inspect(response)

    {:ok, indexed_doc} = Document.get(@elastic_url, "seraph", "user", response.body["_id"])

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
    "#{hostname}-elastic-consumer"
  end
end
