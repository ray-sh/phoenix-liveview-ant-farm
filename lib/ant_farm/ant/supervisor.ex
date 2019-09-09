defmodule AntFarm.Ant.Supervisor do
  @moduledoc """
  DynamicSupervisor which starts and supervises ant GenServers.
  """
  use DynamicSupervisor

  alias AntFarm.Ant

  @id_length 15

  @doc """
  Starts the supervisor process
  """
  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @doc """
  Starts a supervised ant process
  """
  def start_child do
    spec = {Ant, id: generate_id()}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @doc """
  Starts `count` number of ant processes
  """
  def populate(count \\ 1) do
    for _ <- 1..count, do: start_child()
  end

  @impl true
  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Returns all its children states
  """
  def ants do
    __MODULE__
    |> DynamicSupervisor.which_children()
    |> Task.async_stream(&get_ant_state/1)
    |> Enum.map(fn {:ok, state} -> state end)
  end

  def ant_pids do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(&elem(&1,1))
  end

  @doc """
  Makes all ants go crazy!
  """
  def panic do
    __MODULE__
    |> DynamicSupervisor.which_children()
    |> Enum.each(&do_panic/1)
  end

  defp generate_id do
    @id_length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp get_ant_state({_, pid, _, _}) do
    Ant.get_state(pid)
  end

  defp do_panic({_, pid, _, _}), do: Ant.panic(pid)
end
