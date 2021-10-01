defmodule Medio do
  @moduledoc """
    Suppose we have a python script "./python_scripts/predict.py" and the "python"
    executable is available in PATH.

    # Start the port passing some initial params:
    {:ok, name} = Medio.start(Medio.Primo, "python", Path.expand("./python_scripts/predict.py"), "model foo")

    # then call for predict:
    Medio.predict(name, %{foo: "baz"})
  """

  alias Medio.{Mediator, PortSupervisor}
  @uuid4_size 16
  @timeout :timer.seconds(5)

  @doc """
    name: Medio.Primo                                   # atom, unique name
    python: "python"                                    # path to python executable
    init_arguments: "model_id_to_load? foo"             # initial arguments, passed to the script
    script: Path.expand("./python_scripts/predict.py")  # path to python script
  """
  def start(name, python, script, init_args)
      when is_atom(name) and is_binary(python) and is_binary(script) and is_binary(init_args) do
    case DynamicSupervisor.start_child(PortSupervisor, spec(name, python, script, init_args)) do
      {:ok, _pid} -> {:ok, name}
      {:error, reason} -> {:error, reason}
    end
  end

  def stop(name), do: DynamicSupervisor.terminate_child(PortSupervisor, Process.whereis(name))

  def predict_async(pid, %{} = data) do
    frame_id = UUID.uuid4() |> UUID.string_to_binary!()
    predict_async(pid, frame_id, data)
  end

  def predict_async(pid, frame_id, %{} = data) when byte_size(frame_id) == @uuid4_size do
    Mediator.request_predict(pid, frame_id, %{} = data)
  end

  def predict_await(frame_id, timeout \\ @timeout) do
    receive do
      {:ok, ^frame_id, result} -> {:ok, result}
      {:error, ^frame_id, reason} -> {:error, reason}
    after
      timeout -> {:error, {:detection_timeout, frame_id}}
    end
  end

  def predict(pid, %{} = data, timeout \\ @timeout) do
    predict_async(pid, %{} = data)
    |> predict_await(timeout)
  end

  defp spec(name, python, script, init_args) do
    config = [
      name: name,
      python: python,
      script: script,
      init_arguments: init_args
    ]

    Supervisor.child_spec({Mediator, config}, id: name)
  end
end
