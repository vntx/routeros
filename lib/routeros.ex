defmodule Routeros do
  @moduledoc """
  Documentation for Routeros.
  """

  use Application

  def start(_type, _args) do
    # import Supervisor.Spec
    # children = [
    #  supervisor(Routeros.Supervisor, [], [restart: :permanent, name: __MODULE__])
    # ]
    # Supervisor.start_link(children, strategy: :one_for_one )
    Routeros.Supervisor.start_link()
    {:ok, self()}
  end
end
