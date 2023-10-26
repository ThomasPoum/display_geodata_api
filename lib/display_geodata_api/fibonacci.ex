defmodule DisplayGeodataApi.Fibonacci do
  @moduledoc """
  Legacy de l'interview avec KBRW ;)
  """

  def fibonacci(0) do
    0
  end

  def fibonacci(1) do
    1
  end

  def fibonacci(n) do
    fibonacci(n - 1) + fibonacci(n - 2)
  end

  def calculate(n) do
    {_, result} =
      1..(n - 1)
      |> Enum.reduce({0, 1}, fn _, {a, b} -> {b, a + b} end)

    result
  end

  def sequence(n) do
    Stream.scan(0..(n - 1), {0, 1}, fn _, {a, b} -> {b, a + b} end)
    |> Stream.map(&elem(&1, 0))
    |> Enum.take(n)
  end
end
