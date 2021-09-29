defmodule MedioTest do
  use ExUnit.Case
  doctest Medio

  test "greets the world" do
    assert Medio.hello() == :world
  end
end
