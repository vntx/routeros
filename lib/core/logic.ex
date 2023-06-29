defmodule Routeros.Logic do
  @moduledoc false
  alias Routeros.Api
  alias Routeros.Core
  alias Routeros.Utils

  def do_login(pid, login, password) do
    Api.write_sentence(pid, ["/login"])
    salt = get_salt(Api.read_sentence(pid))
    hash = count_hash(password, salt)
    login_request = form_login_sentence(login, hash)

    case String.length(Enum.at(login_request, 2)) do
      44 ->
        Api.write_sentence(pid, login_request)

        case Api.read_sentence(pid) do
          {:done, _} ->
            :ok

          {:trap, a} ->
            :trap

          _ ->
            :ok
        end

      _ ->
        do_login(pid, login, password)
    end
  end

  def get_salt({:done, login_greeting}) do
    [_, code] = login_greeting
    code -- ~c"=ret="
  end

  def crypto(password, bin_md5) do
    [0 | password]
    |> Enum.concat(bin_md5)
    |> :erlang.md5()
    |> :erlang.binary_to_list()
    |> Utils.binary_to_hex()
  end

  def count_hash(password, salt) do
    bin_md5 = Utils.hex_to_binary(salt)
    a = crypto(password, bin_md5)
  end

  def form_login_sentence(login, hash) do
    name = Enum.join(["=name=", login], "")
    code = Enum.join(["=response=00", Enum.concat(hash)])
    ["/login", name, code]
  end

  def send_command(pid, socket, list) do
    a = Api.write_sentence(socket, list)
    Api.read_block(socket)
  end
end
