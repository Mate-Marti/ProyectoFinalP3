defmodule GestorZonas do
  use GenServer

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def registrar_zona(nodo \\ Node.self(), username, cod, nom, nivel, pers \\ 0) do
    GenServer.call(destino(nodo), {:registrar_zona, username, cod, nom, nivel, pers})
  end

  def agregar_sector(nodo \\ Node.self(), username, cod_zona, cod_sector, nom_sector, pers \\ 0) do
    GenServer.call(destino(nodo), {:agregar_sector, username, cod_zona, cod_sector, nom_sector, pers})
  end

  def agregar_punto_atencion(nodo \\ Node.self(), username, cod_zona, cod_sector, punto) do
    GenServer.call(destino(nodo), {:agregar_punto_atencion, username, cod_zona, cod_sector, punto})
  end

  def consultar_zona(nodo \\ Node.self(), cod_zona) do
    GenServer.call(destino(nodo), {:consultar_zona, cod_zona})
  end

  def estadisticas_zona(nodo \\ Node.self(), cod_zona) do
    GenServer.call(destino(nodo), {:estadisticas_zona, cod_zona})
  end

  def listar_zonas(nodo \\ Node.self()) do
    GenServer.call(destino(nodo), :listar_zonas)
  end

  def asociar_elemento(cod_zona, tipo, id_elemento) do
    GenServer.call(__MODULE__, {:asociar_elemento, cod_zona, tipo, id_elemento})
  end

  defp destino(nodo), do: if(nodo == Node.self(), do: __MODULE__, else: {__MODULE__, nodo})

  @impl true
  def init(:ok) do
    {:ok, GestorPersistencia.obtener_lista(:zonas)}
  end

  @impl true
  def handle_call({:registrar_zona, username, cod, nom, nivel, pers}, _from, zonas) do
    with {:ok, _usuario} <- GestorUsuarios.validar_y_registrar(username, :registrar_zona, "registrar_zona #{cod}"),
         false <- existe_codigo?(zonas, cod),
         {:ok, zona} <- Zona.crear_zona(cod, nom, nivel, pers) do
      nuevas_zonas = [zona | zonas]
      GestorPersistencia.actualizar_lista(:zonas, nuevas_zonas)
      {:reply, {:ok, zona}, nuevas_zonas}
    else
      true -> {:reply, {:error, "el código de zona #{cod} ya existe"}, zonas}
      error -> {:reply, error, zonas}
    end
  end

  @impl true
  def handle_call({:agregar_sector, username, cod_zona, cod_sector, nom_sector, pers}, _from, zonas) do
    with {:ok, _usuario} <- GestorUsuarios.validar_y_registrar(username, :registrar_zona, "agregar_sector #{cod_sector}"),
         {:ok, zona} <- buscar_por_codigo(zonas, cod_zona) do
      zona_act = Zona.agregar_sector(zona, cod_sector, nom_sector, pers)
      nuevas_zonas = reemplazar_por_codigo(zonas, zona_act)
      GestorPersistencia.actualizar_lista(:zonas, nuevas_zonas)
      {:reply, {:ok, zona_act}, nuevas_zonas}
    else
      error -> {:reply, error, zonas}
    end
  end

  @impl true
  def handle_call({:agregar_punto_atencion, username, cod_zona, cod_sector, punto}, _from, zonas) do
    with {:ok, _usuario} <- GestorUsuarios.validar_y_registrar(username, :registrar_zona, "agregar_punto #{punto}"),
         {:ok, zona} <- buscar_por_codigo(zonas, cod_zona) do
      zona_act = Zona.agregar_punto_atencion(zona, cod_sector, punto)
      nuevas_zonas = reemplazar_por_codigo(zonas, zona_act)
      GestorPersistencia.actualizar_lista(:zonas, nuevas_zonas)
      {:reply, {:ok, zona_act}, nuevas_zonas}
    else
      error -> {:reply, error, zonas}
    end
  end

  @impl true
  def handle_call({:consultar_zona, cod_zona}, _from, zonas) do
    case buscar_por_codigo(zonas, cod_zona) do
      {:ok, zona} -> {:reply, {:ok, Zona.estado_general(zona)}, zonas}
      error -> {:reply, error, zonas}
    end
  end

  @impl true
  def handle_call({:estadisticas_zona, cod_zona}, _from, zonas) do
    case buscar_por_codigo(zonas, cod_zona) do
      {:ok, zona} -> {:reply, {:ok, Zona.estadisticas_acumuladas(zona)}, zonas}
      error -> {:reply, error, zonas}
    end
  end

  @impl true
  def handle_call(:listar_zonas, _from, zonas) do
    {:reply, {:ok, zonas}, zonas}
  end

  @impl true
  def handle_call({:asociar_elemento, cod_zona, tipo, id_elemento}, _from, zonas) do
    nuevas_zonas = asociar_rec(zonas, cod_zona, tipo, id_elemento)
    GestorPersistencia.actualizar_lista(:zonas, nuevas_zonas)
    {:reply, :ok, nuevas_zonas}
  end

  defp existe_codigo?([], _cod), do: false
  defp existe_codigo?([h | _t], cod) when h.codigo == cod, do: true
  defp existe_codigo?([_h | t], cod), do: existe_codigo?(t, cod)

  defp buscar_por_codigo([], cod), do: {:error, "código de zona #{cod} no encontrado"}
  defp buscar_por_codigo([h | _t], cod) when h.codigo == cod, do: {:ok, h}
  defp buscar_por_codigo([_h | t], cod), do: buscar_por_codigo(t, cod)

  defp reemplazar_por_codigo([], _item), do: []
  defp reemplazar_por_codigo([h | t], item) when h.codigo == item.codigo, do: [item | t]
  defp reemplazar_por_codigo([h | t], item), do: [h | reemplazar_por_codigo(t, item)]

  defp asociar_rec([], _cod_zona, _tipo, _id), do: []
  defp asociar_rec([z | t], cod_zona, tipo, id) when z.codigo == cod_zona do
    [Zona.asociar(z, tipo, id) | t]
  end
  defp asociar_rec([z | t], cod_zona, tipo, id), do: [z | asociar_rec(t, cod_zona, tipo, id)]
end
