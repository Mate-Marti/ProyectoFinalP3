  defmodule GestorPersistencia do
  use GenServer
  @moduledoc """
  GenServer que gestiona la persistencia de datos del sistema de emergencias.
  Se encarga de cargar los datos desde el archivo al iniciar y guardar los cambios
  en el archivo cuando se actualizan las listas de entidades.
  """
  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def obtener_lista(clave) do
    GenServer.call(__MODULE__, {:obtener, clave})
  end

  def actualizar_lista(clave, nueva_lista) do
    GenServer.call(__MODULE__, {:actualizar, clave, nueva_lista})
  end

  @impl true
  def init(:ok) do
    {:ok, Persistencia.cargar_todo()}
  end

  @impl true
  def handle_call({:obtener, clave}, _from, estado) do
    {:reply, Map.get(estado, clave, []), estado}
  end

  @impl true
  def handle_call({:actualizar, clave, nueva_lista}, _from, estado) do
    nuevo_estado = Map.put(estado, clave, nueva_lista)
    Persistencia.guardar_todo(nuevo_estado)
    {:reply, :ok, nuevo_estado}
  end
end
