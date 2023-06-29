defmodule Routeros.Api do
  @moduledoc false
  alias Routeros.Utils

  @eof ""

  def close(:undefined) do
    :ok
  end

  def close(pid) do
    :gen_tcp.close(pid)
  end

  def write_sentence(pid, sentences) do
    Enum.each(sentences, fn x -> write_word(pid, x) end)
    write_word(pid, @eof)
  end

  def write_word(pid, word) do
    len =
      word
      |> String.to_charlist()
      |> :erlang.length()
      |> Utils.encode_len()

    len2 =
      word
      |> String.to_charlist()
      |> :erlang.length()

    case :gen_tcp.send(pid, len) do
      :ok ->
        :gen_tcp.send(pid, word)

      _ ->
        :ok
    end
  end

  def read_block(pid, block \\ []) do
    case read_sentence(pid) do
      {false, sentence} ->
        read_block(pid, [sentence | block])

      {_result, sentence} ->
        IO.puts("send command #{inspect(sentence)}")
        Enum.reverse([sentence | block])
    end
  end

  def read_sentence(pid) do
    read_sentence(pid, [], false)
  end

  def read_sentence(pid, acc, spec) do
    word = read_word(pid)

    case word do
      [] -> {spec, Enum.reverse(acc)}
      ~c"!done" -> read_sentence(pid, [word | acc], :done)
      ~c"!trap" -> read_sentence(pid, [word | acc], :trap)
      ~c"!fatal" -> read_sentence(pid, [word | acc], :fatal)
      data -> read_sentence(pid, [data | acc], spec)
    end
  end

  def read_word(pid) do
    {:ok, [first_len]} = :gen_tcp.recv(pid, 1)

    case :binary.decode_unsigned(Utils.decode_len(first_len, pid)) do
      0 ->
        []

      len ->
        {:ok, word} = :gen_tcp.recv(pid, len)
        word
    end
  end
end
