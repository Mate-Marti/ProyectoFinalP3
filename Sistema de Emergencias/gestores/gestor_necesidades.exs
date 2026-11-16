defmodule GestorNecesidades do
  use GenServer

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def registrar_necesidad(nodo \\ Node.self(), username, id, tipo, desc, cant, zona, prio) do
    GenServer.call(destino(nodo), {:registrar_necesidad, username, id, tipo, desc, cant, zona, prio})
  end

  def listar_necesidades(nodo \\ Node.self(), zona \\ nil, tipo \\ nil, prio \\ nil, est \\ nil) do
    GenServer.call(destino(nodo), {:listar_necesidades, zona, tipo, prio, est})
  end

  def cambiar_estado(nodo \\ Node.self(), username, id_nec, nuevo_estado) do
    GenServer.call(destino(nodo), {:cambiar_estado, username, id_nec, nuevo_estado})
  end

  def asignar_recurso(nodo \\ Node.self(), username, id_nec, cod_o_cat, cantidad) do
    GenServer.call(destino(nodo), {:asignar_recurso, username, id_nec, cod_o_cat, cantidad})
  end

  defp destino(nodo), do: if(nodo == Node.self(), do: __MODULE__, else: {__MODULE__, nodo})

  @impl true
  def init(:ok) do
    {:ok, GestorPersistencia.obtener_lista(:necesidades)}
  end

  @impl true
  def handle_call({:registrar_necesidad, username, id, tipo, desc, cant, zona, prio}, _from, necesidades) do
    with {:ok, _usuario} <- GestorUsuarios.validar_y_registrar(username, :registrar_necesidad, "registrar_necesidad #{id}"),
         false <- existe_id?(necesidades, id),
         true <- GestorZonas.existe_zona?(zona),
         {:ok, necesidad} <- Necesidad.crear_necesidad(id, tipo, desc, cant, zona, prio, username) do
      GestorZonas.asociar_elemento(zona, :necesidades, id)
      nuevas_necesidades = [necesidad | necesidades]
      GestorPersistencia.actualizar_lista(:necesidades, nuevas_necesidades)
      {:reply, {:ok, necesidad}, nuevas_necesidades}
    else
      true -> {:reply, {:error, "el id de necesidad #{id} ya existe"}, necesidades}
      false -> {:reply, {:error, "La zona '#{zona}' no existe. Regístrela primero"}, necesidades}
      error -> {:reply, error, necesidades}
    end
  end

  @impl true
  def handle_call({:listar_necesidades, zona, tipo, prio, est}, _from, necesidades) do
    filtradas =
      necesidades
      |> Necesidad.filtrar_necesidades(zona, tipo, prio, est)
      |> Necesidad.ordenar_por_prioridad()

    {:reply, {:ok, filtradas}, necesidades}
  end

  @impl true
  def handle_call({:cambiar_estado, username, id_nec, nuevo_est}, _from, necesidades) do
    with {:ok, _usuario} <- GestorUsuarios.validar_y_registrar(username, :asignar_recursos, "estado_necesidad #{id_nec} -> #{nuevo_est}"),
         {:ok, necesidad} <- buscar_por_id(necesidades, id_nec),
         {:ok, nec_act} <- Necesidad.cambiar_estado(necesidad, nuevo_est) do
      nuevas_necesidades = reemplazar_por_id(necesidades, nec_act)
      GestorPersistencia.actualizar_lista(:necesidades, nuevas_necesidades)
      {:reply, {:ok, nec_act}, nuevas_necesidades}
    else
      error -> {:reply, error, necesidades}
    end
  end

  @impl true
  def handle_call({:asignar_recurso, username, id_nec, cod_o_cat, cantidad}, _from, necesidades) do
    with {:ok, _usuario} <- GestorUsuarios.validar_y_registrar(username, 
    :asignar_recursos,
     "asignar_recurso #{cod_o_cat} -> #{id_nec}"),
         {:ok, necesidad} <- buscar_por_id(necesidades, id_nec),
          {:ok, nec_act} <- Necesidad.registrar_asignacion(necesidad, cantidad),
         {:ok, recurso_act} <- GestorRecursos.reservar_recurso(cod_o_cat, cantidad)do
      nuevas_necesidades = reemplazar_por_id(necesidades, nec_act)
      GestorPersistencia.actualizar_lista(:necesidades, nuevas_necesidades)
      {:reply, {:ok, %{recurso: recurso_act, necesidad: nec_act}}, nuevas_necesidades}
    else
      error -> {:reply, error, necesidades}
    end
  end

  defp existe_id?([], _id), do: false
  defp existe_id?([h | _t], id) when h.id == id, do: true
  defp existe_id?([_h | t], id), do: existe_id?(t, id)

  defp buscar_por_id([], id), do: {:error, "necesidad #{id} no encontrada"}
  defp buscar_por_id([h | _t], id) when h.id == id, do: {:ok, h}
  defp buscar_por_id([_h | t], id), do: buscar_por_id(t, id)

  defp reemplazar_por_id([], _item), do: []
  defp reemplazar_por_id([h | t], item) when h.id == item.id, do: [item | t]
  defp reemplazar_por_id([h | t], item), do: [h | reemplazar_por_id(t, item)]
end
