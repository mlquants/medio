defmodule MedioTest do
  use ExUnit.Case
  doctest Medio

  @moduletag :capture_log

  describe "start / stop" do
    test "port is open and closed on exit" do
      unique_name = Medio.Primo
      path_to_script = Path.expand("./python_scripts/predict.py")
      initial_arguments = "model foo"

      {:ok, mediator} = Medio.start(unique_name, "python", path_to_script, initial_arguments)

      %{port: port} = :sys.get_state(mediator)

      assert Port.info(port)

      :ok = Medio.stop(mediator)

      refute Port.info(port)
    end

    test "start multiple" do
      path_to_script = Path.expand("./python_scripts/predict.py")
      initial_arguments = "model foo"
      {:ok, mediator_1} = Medio.start(Medio.Primo, "python", path_to_script, initial_arguments)
      {:ok, mediator_2} = Medio.start(Medio.Secundo, "python", path_to_script, initial_arguments)

      %{port: port_1} = :sys.get_state(mediator_1)
      %{port: port_2} = :sys.get_state(mediator_2)
      refute port_1 == port_2

      :ok = Medio.stop(mediator_1)
      refute Port.info(port_1)
      assert Port.info(port_2)

      :ok = Medio.stop(mediator_2)
      refute Port.info(port_2)
    end
  end

  describe "predict" do
    setup do
      path_to_script = Path.expand("./python_scripts/predict.py")
      initial_arguments = "model foo"

      {:ok, mediator} = Medio.start(Medio.Primo, "python", path_to_script, initial_arguments)
      on_exit(fn -> :ok = Medio.stop(mediator) end)

      %{mediator: mediator}
    end

    test "synchronous", %{mediator: mediator} do
      assert {:ok,
              %{
                "based_on_input" => %{
                  "data" => %{"foo" => "bar"},
                  "id" => _
                },
                "context" => %{"init_arguments" => []},
                "prediction" => "Partial clouds"
              }} = Medio.predict(mediator, %{foo: "bar"})
    end

    test "asynchronous", %{mediator: mediator} do
      frame_id = Medio.predict_async(mediator, %{foo: "bar"})

      assert {:ok,
              %{
                "based_on_input" => %{
                  "data" => %{"foo" => "bar"},
                  "id" => _
                },
                "context" => %{"init_arguments" => []},
                "prediction" => "Partial clouds"
              }} = Medio.predict_await(frame_id)
    end

    test "asynchronous with two ports", %{mediator: mediator_1} do
      path_to_script = Path.expand("./python_scripts/predict.py")
      initial_arguments = "model foo"
      {:ok, mediator_2} = Medio.start(Medio.Secundo, "python", path_to_script, initial_arguments)

      frame_id_1 = Medio.predict_async(mediator_1, %{foo: "bar"})
      frame_id_2 = Medio.predict_async(mediator_2, %{foo: "baz"})

      assert {:ok, %{"based_on_input" => %{"id" => ^frame_id_1}}} =
               Medio.predict_await(frame_id_1)

      assert {:ok, %{"based_on_input" => %{"id" => ^frame_id_2}}} =
               Medio.predict_await(frame_id_2)
    end

    test "error", %{mediator: mediator} do
      assert {:error, _reason} = Medio.predict(mediator, %{error: true})
      # normal operations are not affected:
      assert {:ok, %{}} = Medio.predict(mediator, %{foo: :bar})
    end

    test "runtime raise", %{mediator: mediator} do
      %{port: initial_port} = :sys.get_state(mediator)

      assert {:error, {:detection_timeout, _frame_id}} =
               Medio.predict(mediator, %{raise: true}, 100)

      # since there was a runtime error on python side,
      # that process on the other side of the port is restarted and we get a new port:
      %{port: new_port} = :sys.get_state(mediator)

      refute initial_port == new_port

      # subsequent operations are not affected:
      assert {:ok, %{}} = Medio.predict(mediator, %{foo: :bar})
    end

    test "runtime error async", %{mediator: mediator} do
      frame_id = Medio.predict_async(mediator, %{raise: true})

      assert {:error, _reason} = Medio.predict_await(frame_id, 100)
      # subsequent operations are not affected:
      assert {:ok, %{}} = Medio.predict(mediator, %{foo: :bar})
    end
  end
end
