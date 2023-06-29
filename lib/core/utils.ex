defmodule Routeros.Utils do
  @moduledoc false
  import Bitwise

  def encode_len(len) do
    cond do
      len >= 0 && len <= 0x7F ->
        # 1 bytes len
        :binary.encode_unsigned(len)

      len >= 0x80 && len <= 0x3FFF ->
        encode(len, 0x8000)

      len >= 0x4000 && len <= 0x1FFFFF ->
        encode(len, 0xC00000)

      len >= 0x200000 && len <= 0xFFFFFFF ->
        encode(len, 0xE0000000)

      true ->
        encode(len, 0xF0)
    end
  end

  def encode(len, bor1) do
    binary = :binary.encode_unsigned(len)
    [first | tail] = :binary.bin_to_list(binary)
    :erlang.list_to_binary([bor(first, bor1) | tail])
  end

  def decode_len(len, pid) do
    cond do
      band(len, base_to_num_decode("E0")) == base_to_num_decode("E0") ->
        {:ok, first} = band(len, base_to_num_decode("1F"))
        {:ok, rest} = :gen_tcp.recv(pid, 3)
        :erlang.list_to_binary([first | rest])

      band(len, base_to_num_decode("C0")) == base_to_num_decode("C0") ->
        first = band(len, base_to_num_decode("3F"))
        {:ok, rest} = :gen_tcp.recv(pid, 2)
        :erlang.list_to_binary([first | rest])

      band(len, base_to_num_decode("80")) == base_to_num_decode("80") ->
        first = band(len, base_to_num_decode("7F"))
        {:ok, rest} = :gen_tcp.recv(pid, 1)
        :erlang.list_to_binary([first | rest])

      true ->
        <<len>>
    end
  end

  def base_to_num_decode(t) do
    {:ok, r} = Base.decode16(t)
    [enc1 | _] = :erlang.binary_to_list(r)
    enc1
  end

  def base_decode(t) do
    {:ok, r} = Base.decode16(t)
    r
  end

  def hex_to_binary(hex_list) do
    a =
      hex_list
      |> part()
      |> Enum.reduce(
        [],
        fn x, acc ->
          [:erlang.list_to_integer(x, 16) | acc]
        end
      )

    a
  end

  def binary_to_hex(bin_list) do
    bin_list
    |> Enum.reduce([], fn x, acc ->
      y = :erlang.integer_to_list(x, 16)

      [y | acc]
    end)
    |> Enum.reverse()
  end

  defp part(list) do
    a = list

    if :erlang.length(list) == 32 do
      part(list, [])
    else
      :error1
    end
  end

  defp part([], acc) do
    acc
  end

  defp part([h1, h2 | t], acc) do
    part(t, [[h1, h2] | acc])
  end
end
