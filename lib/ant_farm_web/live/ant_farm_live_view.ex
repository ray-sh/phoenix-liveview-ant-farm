defmodule AntFarmWeb.AntFarmLiveView do
  use Phoenix.LiveView

  alias AntFarm.Ant.Supervisor, as: Colony

  @timeout 60

  @impl true
  def render(assigns) do
    AntFarmWeb.PageView.render("ant_farm.html", assigns)
  end

  @impl true
  def mount(_session, socket) do
    #if connected?(socket), do: schedule()
    if connected?(socket) do
      Phoenix.PubSub.subscribe(AntFarm.PubSub, "ant_updates")
    end
    ants = Colony.ants()
    {:ok, assign(socket, panic: false, ants: ants)}
  end

  @impl true
  def handle_event("tap", _value, socket) do
    Colony.panic()
    Process.send_after(self(), :chill, 1000)
    {:noreply, assign(socket, panic: true)}
  end

  def handle_info({:ant_update, new_state}, socket) do
    {:noreply, assign(socket, ants: [new_state] )}
  end

  def handle_info(:tick, socket) do
    schedule()
    ants = Colony.ants()
    {:noreply, assign(socket, ants: ants)}
  end

  def handle_info(:chill, socket) do
    {:noreply, assign(socket, panic: false)}
  end

  defp schedule do
    Process.send_after(self(), :tick, @timeout)
  end
end
