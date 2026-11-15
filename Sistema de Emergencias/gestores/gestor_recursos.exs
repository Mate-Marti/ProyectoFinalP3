defmodule GestorRecursos do
  use GenServer

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def registrar_recurso(nodo \\ Node.self(), username, cod, nom, cat, cant, uni, ubi) do
    GenServer.call(destino(nodo), {:registrar_recurso, username, cod, nom, cat, cant, uni, ubi})
  end

  def entrada_recurso(nodo \\ Node.self(), username, cod, cant) do
    GenServer.call(destino(nodo), {:entrada_recurso, username, cod, cant})
  end

  def transferir_recurso(nodo \\ Node.self(), username, cod_origen, ubi_origen, ubi_destino, cant) do
    GenServer.call(destino(nodo), {:transferir_recurso, username, cod_origen, ubi_origen, ubi_destino, cant})
  end

  def listar_recursos(nodo \\ Node.self(), cat \\ nil, zona \\ nil) do
    GenServer.call(destino(nodo), {:listar_recursos, cat, zona})
  end

  def recursos_criticos(nodo \\ Node.self(), umbral \\ 10) do
    GenServer.call(destino(nodo), {:recursos_criticos, umbral})
  end

  # Llamado atómicamente desde GestorNecesidades al asignar recursos
  def reservar_recurso(cod_o_cat, cantidad) do
    GenServer.call(__MODULE__, {:reservar_recurso, cod_o_cat, cantidad})
  end

  defp destino(nodo), do: if(nodo == Node.self(), do: __MODULE__, else: {__MODULE__, nodo})

  @impl true
  def init(:ok) do
    {:ok, GestorPersistencia.obtener_lista(:recursos)}
  end

  @impl true
  def handle_call({:registrar_recurso, username, cod, nom, cat, cant, uni, ubi}, _from, recursos) do
    with {:ok, _usuario} <- GestorUsuarios.validar_y_registrar(username, :registrar_recursos, "registrar_recurso #{cod}"),
         false <- existe_codigo?(recursos, cod),
         {:ok, recurso} <- Recurso.crear_recurso(cod, nom, cat, cant, uni, ubi) do
      GestorZonas.asociar_elemento(ubi, :recursos, cod)
      nuevos_recursos = [recurso | recursos]
      GestorPersistencia.actualizar_lista(:recursos, nuevos_recursos)
      {:reply, {:ok, recurso}, nuevos_recursos}
    else
      true -> {:reply, {:error, "el código de recurso #{cod} ya existe"}, recursos}
      error -> {:reply, error, recursos}
    end
  end

  @impl true
  def handle_call({:entrada_recurso, username, cod, cant}, _from, recursos) do
    with {:ok, _usuario} <- GestorUsuarios.validar_y_registrar(username, :registrar_recursos, "entrada_recurso #{cod} +#{cant}"),
         {:ok, recurso} <- buscar_por_codigo(recursos, cod),
         {:ok, rec_act} <- Recurso.entrada(recurso, cant) do
      nuevos_recursos = reemplazar_por_codigo(recursos, rec_act)
      GestorPersistencia.actualizar_lista(:recursos, nuevos_recursos)
      {:reply, {:ok, rec_act}, nuevos_recursos}
    else
      error -> {:reply, error, recursos}
    end
  end

  @impl true
  def handle_call({:reservar_recurso, cod_o_cat, cantidad}, _from, recursos) do
    with {:ok, recurso} <- buscar_disponible(recursos, cod_o_cat, cantidad),
         {:ok, recurso_act} <- Recurso.salida(recurso, cantidad) do
      nuevos_recursos = reemplazar_por_codigo(recursos, recurso_act)
      GestorPersistencia.actualizar_lista(:recursos, nuevos_recursos)
      {:reply, {:ok, recurso_act}, nuevos_recursos}
    else
      error -> {:reply, error, recursos}
    end
  end

  @impl true
  def handle_call({:transferir_recurso, username, cod_origen, _ubi_origen, ubi_destino, cantidad}, _from, recursos) do
    with {:ok, _usuario} <- GestorUsuarios.validar_y_registrar(username, :transferir_recursos, "transferir #{cod_origen} -> #{ubi_destino}"),
         {:ok, origen} <- buscar_por_codigo(recursos, cod_origen) do
      cod_dest = "#{cod_origen}_#{ubi_destino}"

      destino =
        case buscar_por_codigo(recursos, cod_dest) do
          {:ok, existente} ->
            existente

          {:error, _} ->
            {:ok, nuevo} = Recurso.crear_recurso(cod_dest, origen.nombre, origen.categoria, 0, origen.unidad, ubi_destino)
            nuevo
        end

      case Recurso.transferir(origen, destino, cantidad) do
        {:ok, origen_act, destino_act} ->
          sin_dest = eliminar_por_codigo(recursos, cod_dest)
          nuevos_recursos = [destino_act | reemplazar_por_codigo(sin_dest, origen_act)]
          GestorPersistencia.actualizar_lista(:recursos, nuevos_recursos)
          {:reply, {:ok, %{origen: origen_act, destino: destino_act}}, nuevos_recursos}

        error ->
          {:reply, error, recursos}
      end
    else
      error -> {:reply, error, recursos}
    end
  end

  @impl true
  def handle_call({:listar_recursos, cat, zona}, _from, recursos) do
    {:reply, {:ok, Recurso.consultar_disponibilidad(recursos, cat, zona)}, recursos}
  end

  @impl true
  def handle_call({:recursos_criticos, umbral}, _from, recursos) do
    {:reply, {:ok, Recurso.recursos_criticos(recursos, umbral)}, recursos}
  end

  defp existe_codigo?([], _cod), do: false
  defp existe_codigo?([h | _t], cod) when h.codigo == cod, do: true
  defp existe_codigo?([_h | t], cod), do: existe_codigo?(t, cod)

  defp buscar_por_codigo([], cod), do: {:error, "recurso #{cod} no encontrado"}
  defp buscar_por_codigo([h | _t], cod) when h.codigo == cod, do: {:ok, h}
  defp buscar_por_codigo([_h | t], cod), do: buscar_por_codigo(t, cod)

  defp buscar_disponible([], cod_o_cat, _cant),
    do: {:error, "inventario insuficiente para #{cod_o_cat}"}

  defp buscar_disponible([r | _t], cod_o_cat, cant)
       when (r.codigo == cod_o_cat or r.categoria == cod_o_cat) and r.cantidad >= cant,
       do: {:ok, r}

  defp buscar_disponible([_r | t], cod_o_cat, cant),
    do: buscar_disponible(t, cod_o_cat, cant)

  defp reemplazar_por_codigo([], _item), do: []
  defp reemplazar_por_codigo([h | t], item) when h.codigo == item.codigo, do: [item | t]
  defp reemplazar_por_codigo([h | t], item), do: [h | reemplazar_por_codigo(t, item)]

  defp eliminar_por_codigo([], _cod), do: []
  defp eliminar_por_codigo([h | t], cod) when h.codigo == cod, do: t
  defp eliminar_por_codigo([h | t], cod), do: [h | eliminar_por_codigo(t, cod)]
end
