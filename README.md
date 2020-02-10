# OpencensusEcto

Telemetry handler that creates Opencensus spans from Ecto query events. Because
Ecto emits telemetry events only after queries have finished, OpencensusEcto
estimates the start time of the span by subtracting the reported total duration
from the current timestamp.

After installing, setup the handler in your application behaviour before your
top-level supervisor starts.

```elixir
OpencensusEcto.setup([:blog, :repo, :query])
```

See the documentation for `OpencensusEcto.setup/2` for additional options that
may be supplied.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `opencensus_ecto` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:opencensus_ecto, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/opencensus_ecto](https://hexdocs.pm/opencensus_ecto).

