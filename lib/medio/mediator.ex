defmodule Medio.Mediator do
  @moduledoc """
  A process responsible for communication with port
  """
  use GenServer
  require Logger

  @uuid4_size 16

  def start_link(opts \\ []) do
    Logger.info("starting port mediator #{opts[:name]} with #{inspect(opts)}")
    GenServer.start_link(__MODULE__, opts, opts)
  end

  def config(configs) do
    configs
    |> Enum.map(fn
      # it finds the full path when not provided
      {:python, path} -> {:python, System.find_executable(path)}
      # it loads the value from the environment variable
      {option, {:system, env_variable}} -> {option, System.get_env(env_variable)}
      # all the other options
      config -> config
    end)
    |> Enum.into(%{})
  end

  def request_predict(pid, frame_id, %{} = data) when byte_size(frame_id) == @uuid4_size do
    GenServer.call(pid, {:predict, frame_id, data})
  end

  @impl true
  def init(opts) do
    config = config(opts)

    {:ok, %{port: open_port(config), requests: %{}, config: config}}
  end

  defp open_port(config) do
    Port.open(
      {:spawn_executable, config.python},
      [:binary, :nouse_stdio, {:packet, 4}, args: [config.script, config.init_arguments]]
    )
    |> tap(&Port.monitor/1)
  end

  @impl true
  def handle_call({:predict, frame_id, %{} = data}, {from_pid, _}, worker) do
    Port.command(worker.port, [frame_id, pack!(data)])
    worker = put_in(worker, [:requests, frame_id], from_pid)
    {:reply, frame_id, worker}
  end

  @impl true
  def handle_info(
        {port, {:data, <<frame_id::binary-size(@uuid4_size), packed_string::binary()>>}},
        %{port: port} = state
      ) do
    # getting from pid and removing the request from the map
    {from_pid, state} = pop_in(state, [:requests, frame_id])

    case unpack!(packed_string) do
      %{"success" => true} = result ->
        send(from_pid, {:ok, frame_id, result})

      %{"success" => false} = result ->
        send(from_pid, {:error, frame_id, result})
    end

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :port, port, :normal}, %{port: port, config: config} = state) do
    new_port = open_port(config)
    {:noreply, %{state | port: new_port}}
  end

  defp pack!(%{} = data) do
    Msgpax.pack!(data)
  end

  defp unpack!(packed_string) when is_binary(packed_string) do
    Msgpax.unpack!(packed_string)
  end
end
