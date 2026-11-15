defmodule SupervisorEmergencia do
  use Supervisor

  def start_link(_opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    children = [
      {GestorPersistencia, []},
      {GestorUsuarios, []},
      {GestorZonas, []},
      {GestorRecursos, []},
      {GestorNecesidades, []},
      {GestorAlbergues, []},
      {GestorFamiliares, []},
      {GestorMascotas, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
