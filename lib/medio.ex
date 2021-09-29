defmodule Medio do
  @moduledoc """
    Suppose we have a python script "./python_scripts/predict.py" and the "python" executable is available in PATH.

    # Start the port passing some initial params:
    {:ok, name} = Medio.start(Medio.Primo, "python", Path.expand("./python_scripts/predict.py"), "model foo")

    # then using this name, call:
    Medio.predict(Medio.Primo, %{foo: "baz"})
  """

  alias Medio.{Mediator, PortSupervisor}
  @uuid4_size 16

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

  def request_predict(pid, %{} = data) do
    image_id = UUID.uuid4() |> UUID.string_to_binary!()
    request_predict(pid, image_id, data)
  end

  def request_predict(pid, image_id, %{} = data) when byte_size(image_id) == @uuid4_size do
    Mediator.request_predict(pid, image_id, %{} = data)
  end

  def await(image_id, timeout \\ 5000) do
    receive do
      {:detected, ^image_id, result} -> result
    after
      timeout -> {:detection_timeout, image_id}
    end
  end

  def predict(pid, %{} = data) do
    request_predict(pid, %{} = data)
    |> await()
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
