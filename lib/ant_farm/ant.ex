defmodule AntFarm.Ant do
  @moduledoc """
  Ant GenServer implementation which stores the
  current state of an ant.
  """

  use GenServer

  alias __MODULE__.{State, Behaviour}
  @timeout 60
  @pubsub_name :ant
  @pubsub_topic "ant_updates"

  @doc false
  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)

    GenServer.start_link(__MODULE__, id, name: name(id))
  end

  def get_state(pid), do: GenServer.call(pid, :get_state)

  def panic(pid), do: GenServer.cast(pid, :panic)

  @impl true
  def init(id) do
    schedule()
    {:ok, State.new(id)}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:perform_actions, state) do
    new_state = Behaviour.process(state)
    schedule()
    Phoenix.PubSub.broadcast(AntFarm.PubSub, @pubsub_topic, {:ant_update, new_state})
    {:noreply, new_state}
  end

  # @impl true
  # def handle_info(_, state) do
  #   {:noreply, state}
  # end

  @impl true
  def handle_cast(:panic, %State{state: :panicking} = state) do
    {:noreply, state}
  end

  def handle_cast(:panic, state) do
    new_state = State.start_panicking(state)
    #Phoenix.PubSub.broadcast会向订阅topic的所有process发送消息，消息不会发给自己
    #这种消息中转的好处是发送者和接收者的解耦，他们不必知道彼此的process，每个process只需要和全局的pubsub打交道就可以
    Phoenix.PubSub.broadcast(AntFarm.PubSub, @pubsub_topic, {:ant_update, new_state})
    {:noreply, new_state}
  end

  defp name(id), do: String.to_atom("ant::" <> id)

  defp schedule do
    Process.send_after(self(), :perform_actions, @timeout)
  end
end
