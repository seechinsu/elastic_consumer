defmodule ElasticConsumer do
  require Logger
  alias GenRMQ.Message
  alias Elastix.{Document, Index, Mapping}

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
  @spec init() :: [
          {:exchange, <<_::48>>}
          | {:prefetch_count, <<_::16>>}
          | {:queue, <<_::88>>}
          | {:routing_key, <<>>}
          | {:uri, nil | binary()},
          ...
        ]
  def init() do
    elastic_create_index()
    elastic_create_user_mapping()

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

  defp elastic_create_user_mapping do
    mapping = %{
      properties: %{
        id: %{type: "integer"},
        email: %{type: "text"},
        inserted_at: %{type: "date"},
        updated_at: %{type: "date"},
        profiles: %{type: "nested"},
        projects: %{type: "nested"},
        avatar: %{type: "object"}
      }
    }

    Mapping.put(@elastic_url, "seraph", "user", mapping)
  end

  def handle_message(%Message{} = message) do
    payload =
      message
      |> Map.fetch!(:payload)
      |> Jason.decode!()
      |> Map.drop(["event"])

    {:ok, response} =
      @elastic_url
      |> Document.index("seraph", "user", payload["id"], payload)

    {:ok, indexed_doc} = Document.get(@elastic_url, "seraph", "user", response.body["_id"])

    # IO.inspect(indexed_doc)

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
