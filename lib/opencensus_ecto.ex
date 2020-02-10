defmodule OpencensusEcto do
  @moduledoc """
  Telemetry handler for creating OpenCensus spans from Ecto query events.
  """

  import Bitwise

  require Record

  Record.defrecordp(
    :span,
    Record.extract(:span, from_lib: "opencensus/include/opencensus.hrl")
  )

  Record.defrecordp(
    :span_ctx,
    Record.extract(:span_ctx, from_lib: "opencensus/include/opencensus.hrl")
  )

  @doc """
  Attaches the OpencensusEcto handler to your repo events. This should be called
  from your application behaviour on startup.

  Example:

      OpencensusEcto.setup([:blog, :repo, :query])

  You may also supply the following options in the second argument:

    * `:time_unit` - a time unit used to convert the values of query phase
      timings, defaults to `:microsecond`. See `System.convert_time_unit/3`

    * `:span_prefix` - the first part of the span name, as a `String.t`,
      defaults to the concatenation of the event name with periods, e.g.
      `"blog.repo.query"`. This will always be followed with a colon and the
      source (the table name for SQL adapters).
  """
  def setup(event_name, config \\ []) do
    :telemetry.attach({__MODULE__, event_name}, event_name, &__MODULE__.handle_event/4, config)
  end

  @doc false
  def handle_event(event, measurements, metadata, config) do
    {end_time, end_offset} = ending = :wts.timestamp()

    with span_ctx(
           trace_id: trace_id,
           trace_options: trace_options,
           tracestate: state,
           span_id: parent_span
         )
         when is_integer(trace_options) and (trace_options &&& 1) != 0 <- :ocp.current_span_ctx() do
      total_time = measurements[:total_time]

      %{
        query: query,
        source: source,
        result: query_result
      } = metadata

      time_unit = Keyword.get(config, :time_unit, :microsecond)

      span_name =
        case Keyword.fetch(config, :span_prefix) do
          {:ok, prefix} -> prefix
          :error -> Enum.join(event, ".")
        end <> ":#{source}"

      base_attributes =
        Map.merge(
          %{
            "query" => query,
            "source" => source,
            "total_time_#{time_unit}s" => System.convert_time_unit(total_time, :native, time_unit)
          },
          case query_result do
            {:ok, _} -> %{}
            _ -> %{"error" => true}
          end
        )

      attributes =
        measurements
        |> Enum.into(%{})
        |> Map.take(~w(decode_time query_time queue_time)a)
        |> Enum.reject(&is_nil(elem(&1, 1)))
        |> Enum.map(fn {k, v} ->
          {"#{k}_#{time_unit}s", System.convert_time_unit(v, :native, time_unit)}
        end)
        |> Enum.into(base_attributes)

      span(
        name: span_name,
        trace_id: trace_id,
        span_id: :opencensus.generate_span_id(),
        tracestate: state,
        start_time: {end_time - total_time, end_offset},
        end_time: ending,
        parent_span_id: parent_span,
        attributes: attributes
      )
      |> :oc_reporter.store_span()
    end
  end
end
