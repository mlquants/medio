# Medio

From latin `mediō` (“be in the middle”)

Efficient interaction between elixir and python can be achieved in a number of different ways.
Here we focus on port streaming.
We focus on a classic ML usecase: load heavy model on init and then do predicts.
This is an attempt to hide a (relative) complexity of ports interaction via simple library.

The work is greatly inspired by https://github.com/poeticoding/yolo_example and an amazing talk https://www.youtube.com/watch?v=FL1qcLemml0

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `medio` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:medio, github: "https://github.com/mlquants/medio"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/medio](https://hexdocs.pm/medio).

