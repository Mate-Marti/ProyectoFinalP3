defmodule GestorMascotas do
  use GenServer

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def reportar_mascota(nodo \\ Node.self(), username, id, tipo, esp, nom, car, col, tam, zona, cont) do
    GenServer.call(destino(nodo), {:reportar_mascota, username, id, tipo, esp, nom, car, col, tam, zona, cont})
  end

  def listar_mascotas(nodo \\ Node.self(), especie \\ nil, zona \\ nil, estado \\ nil) do
    GenServer.call(destino(nodo), {:listar_mascotas, especie, zona, estado})
  end

  def buscar_coincidencias(nodo \\ Node.self()) do
    GenServer.call(destino(nodo), :buscar_coincidencias)
  end

  def confirmar_coincidencia(nodo \\ Node.self(), username, id_perdida, id_encontrada) do
    GenServer.call(destino(nodo), {:confirmar_coincidencia, username, id_perdida, id_encontrada})
  end

  defp destino(nodo), do: if(nodo == Node.self(), do: __MODULE__, else: {__MODULE__, nodo})

  @impl true
  def init(:ok) do
    {:ok, GestorPersistencia.obtener_lista(:mascotas)}
  end

  @impl true
  def handle_call({:reportar_mascota, username, id, tipo, esp, nom, car, col, tam, zona, cont}, _from, mascotas) do
    with {:ok, _usuario} <- 
    GestorUsuarios.validar_y_registrar(username, :reportar_mascota, "reportar_mascota #{id}"),
         false <- existe_id?(mascotas, id),
         true <- GestorZonas.existe_zona?(zona),
         {:ok, reporte} <- ReporteMascota.crear_reporte(id, tipo, esp, nom, car, col, tam, zona, cont) do
      GestorZonas.asociar_elemento(zona, :reportes, id)
      nuevas_mascotas = [reporte | mascotas]
      GestorPersistencia.actualizar_lista(:mascotas, nuevas_mascotas)
      {:reply, {:ok, reporte}, nuevas_mascotas}
    else
      true -> {:reply, {:error, "el id de mascota #{id} ya existe"}, mascotas}
      false -> {:reply, {:error, "La zona '#{zona}' no existe. Regístrela primero"}, mascotas}
      error -> {:reply, error, mascotas}
    end
  end

  @impl true
  def handle_call({:listar_mascotas, especie, zona, est}, _from, mascotas) do
    {:reply, {:ok, ReporteMascota.filtrar_reportes(mascotas, especie, zona, est)}, mascotas}
  end

  @impl true
  def handle_call(:buscar_coincidencias, _from, mascotas) do
    {:reply, {:ok, ReporteMascota.buscar_coincidencias(mascotas)}, mascotas}
  end

  @impl true
  def handle_call({:confirmar_coincidencia, username, id_perdida, id_encontrada}, _from, mascotas) do
    with {:ok, _usuario} <-
     GestorUsuarios.validar_y_registrar(username, :emparejar_mascota, "confirmar_mascota #{id_perdida} y #{id_encontrada}"),
         {:ok, rep_p} <- buscar_por_id(mascotas, id_perdida),
         {:ok, rep_e} <- buscar_por_id(mascotas, id_encontrada),
         {:ok, p_cerrado, e_cerrado} <- ReporteMascota.confirmar_coincidencia(rep_p, rep_e) do
      nuevas_mascotas =
        mascotas
        |> reemplazar_por_id(p_cerrado)
        |> reemplazar_por_id(e_cerrado)

      GestorPersistencia.actualizar_lista(:mascotas, nuevas_mascotas)
      {:reply, {:ok, %{perdida: p_cerrado, encontrada: e_cerrado}}, nuevas_mascotas}
    else
      error -> {:reply, error, mascotas}
    end
  end

  defp existe_id?([], _id), do: false
  defp existe_id?([h | _t], id) when h.id == id, do: true
  defp existe_id?([_h | t], id), do: existe_id?(t, id)

  defp buscar_por_id([], id), do: {:error, "reporte de mascota #{id} no encontrado"}
  defp buscar_por_id([h | _t], id) when h.id == id, do: {:ok, h}
  defp buscar_por_id([_h | t], id), do: buscar_por_id(t, id)

  defp reemplazar_por_id([], _item), do: []
  defp reemplazar_por_id([h | t], item) when h.id == item.id, do: [item | t]
  defp reemplazar_por_id([h | t], item), do: [h | reemplazar_por_id(t, item)]
end
