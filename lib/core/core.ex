defmodule Routeros.Core do
  @moduledoc false
  use GenServer

  alias Routeros.Api
  alias Routeros.Logic

  require Logger

  defmodule State do
    @moduledoc false
    defstruct login: false, pid: nil, socket: nil, port: nil, resp: nil, request_count: 0
  end

  @timeout 5000
  @config Application.get_env(:routeros, :router)
  # Client

  def start_link(count \\ 0) do
    p = GenServer.start_link(__MODULE__, @config, [{:name, __MODULE__}])

    case p do
      {:error, _} ->
        cond do
          count < 10 ->
            IO.puts("connecting to device attempt \##{count}")
            start_link(count + 1)

          true ->
            IO.puts("connection to device failed ")
        end

      {:ok, _} ->
        p
    end
  end

  def init(config) do
    Logger.info("starting up with timeout #{@timeout}")
    {:ok, port} = :gen_tcp.connect(config.host, config.port, [{:active, false}], 5000)

    #  :gen_server.cast(self(), {:connect, config})
    case Logic.do_login(port, config.login, config.password) do
      :ok ->
        IO.puts("PID #{inspect(self())} ")
        {:ok, %State{login: true, pid: self(), socket: port}}

      _ ->
        IO.puts("FAIL #{inspect(self())}")
        {:stop, :fail}
    end
  end

  # Server (callbacks)
  def handle_call({:command, list}, _from, state) do
    Logger.info("sending call #{inspect(list)}")

    if Map.has_key?(state, :socket) do
      e = Routeros.Logic.send_command(self(), state.socket, list)
      me = Map.merge(state, %{resp: e})
      {:reply, e, me}
    else
      IO.puts("command False")
      {:reply, [], state}
    end
  end

  def handle_call(:disconnect, _from, state) do
    Api.close(state.socket)
    {:reply, :disconnected, state}
  end

  def handle_call(:receive, _from, state) do
    IO.puts("#{inspect(state)}")
    reply = Routeros.Api.read_block(state.socket)
    {:reply, reply, state}
  end

  # def handle_call(request, from, state) do
  #   # Call the default implementation from GenSeerver
  #   super(request, from, state)
  # end

  def handle_cast(:resp, state) do
    {:noreply, state}
  end

  def handle_cast(:halt, state) do
    {:stop, :normal, state}
  end

  # def handle_info(_request, state) do
  #   {:noreply, state}
  # end

  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  def terminate(_reason, state) do
    Api.close(state.socket)
    :ok
  end
end
