defmodule OpencensusEctoTest do
  use ExUnit.Case, async: true

  require Record

  for {name, spec} <- Record.extract_all(from_lib: "opencensus/include/opencensus.hrl") do
    Record.defrecord(name, spec)
  end

  setup do
    result = :oc_reporter.register(__MODULE__, receiver: self())

    flush_mailbox()
    result
  end

  ###############################
  ### Reporter support for tests
  ###############################
  @behaviour :oc_reporter

  @impl :oc_reporter
  def init([receiver: _] = opts) do
    opts
  end

  @impl :oc_reporter
  def report([_|_] = spans, receiver: pid) do
    if Process.alive?(pid) do
      Enum.each(spans, &send(pid, &1))
    else
      :ok
    end
  end

  defp report_spans do
    send(:oc_reporter, :report_spans)
  end

  defp flush_mailbox() do
    receive do
      _ -> flush_mailbox()
    after
      100 -> nil
    end
  end

  defmacro assert_span(attrs, timeout \\ 1000) do
    quote do
      report_spans()
      assert_receive span()
    end
  end
end
