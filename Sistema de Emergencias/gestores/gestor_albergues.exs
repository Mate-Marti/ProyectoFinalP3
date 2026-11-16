defmodule GestorAlbergues do
  use GenServer

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def registrar_albergue(nodo \\ Node.self(), username, cod, nom, zona, cap) do
    GenServer.call(destino(nodo), {:registrar_albergue, username, cod, nom, zona, cap})
  end

  def consultar_albergue(nodo \\ Node.self(), cod) do
    GenServer.call(destino(nodo), {:consultar_albergue, cod})
  end

  def ingreso_albergue(nodo \\ Node.self(), username, cod, doc) do
    GenServer.call(destino(nodo), {:ingreso_albergue, username, cod, doc})
  end

  def salida_albergue(nodo \\ Node.self(), username, cod, doc) do
    GenServer.call(destino(nodo), {:salida_albergue, username, cod, doc})
  end

  def reporte_ocupacion(nodo \\ Node.self()) do
    GenServer.call(destino(nodo), :reporte_ocupacion)
  end

  def asociar_recurso(nodo \\ Node.self(), username, cod_albergue, cod_recurso) do
    GenServer.call(destino(nodo), {:asociar_recurso, username, cod_albergue, cod_recurso})
  end

  def asociar_necesidad(nodo \\ Node.self(), username, cod_albergue, id_necesidad) do
    GenServer.call(destino(nodo), {:asociar_necesidad, username, cod_albergue, id_necesidad})
  end

  defp destino(nodo), do: if(nodo == Node.self(), do: __MODULE__, else: {__MODULE__, nodo})

  @impl true
  def init(:ok) do
    {:ok, GestorPersistencia.obtener_lista(:albergues)}
  end

  @impl true
  def handle_call({:registrar_albergue, username, cod, nom, zona, cap}, _from, albergues) do
    with {:ok, _usuario} <- GestorUsuarios.validar_y_registrar(username, :registrar_albergue, "registrar_albergue #{cod}"),
         false <- existe_codigo?(albergues, cod),
         true <- GestorZonas.existe_zona?(zona),
         {:ok, albergue} <- Albergue.crear_albergue(cod, nom, zona, cap) do
      GestorZonas.asociar_elemento(zona, :albergues, cod)
      nuevos_albergues = [albergue | albergues]
      GestorPersistencia.actualizar_lista(:albergues, nuevos_albergues)
      {:reply, {:ok, albergue}, nuevos_albergues}
    else
      true -> {:reply, {:error, "el albergue #{cod} ya existe"}, albergues}
      false -> {:reply, {:error, "La zona '#{zona}' no existe. Regístrela primero"}, albergues}
      error -> {:reply, error, albergues}
    end
  end

  @impl true
  def handle_call({:consultar_albergue, cod}, _from, albergues) do
    case buscar_por_codigo(albergues, cod) do
      {:ok, alb} ->
        info = %{
          albergue: alb,
          cupos_disponibles: Albergue.cupos_disponibles(alb),
          porcentaje_ocupacion: Albergue.porcentaje_ocupacion(alb)
        }
        {:reply, {:ok, info}, albergues}

      error ->
        {:reply, error, albergues}
    end
  end

  @impl true
  def handle_call({:ingreso_albergue, username, cod, doc}, _from, albergues) do
    with {:ok, _usuario} <-
     GestorUsuarios.validar_y_registrar(username, 
     :ingreso_albergue, "ingreso_albergue #{cod} doc #{doc}"),
         {:ok, albergue} <- buscar_por_codigo(albergues, cod),
         {:ok, alb_act} <- Albergue.registrar_ingreso(albergue, doc) do
      nuevos_albergues = reemplazar_por_codigo(albergues, alb_act)
      GestorPersistencia.actualizar_lista(:albergues, nuevos_albergues)
      {:reply, {:ok, alb_act}, nuevos_albergues}
    else
      error -> {:reply, error, albergues}
    end
  end

  @impl true
  def handle_call({:salida_albergue, username, cod, doc}, _from, albergues) do
    with {:ok, _usuario} <- 
    GestorUsuarios.validar_y_registrar(username, 
    :salida_albergue, "salida_albergue #{cod} doc #{doc}"),
         {:ok, albergue} <- buscar_por_codigo(albergues, cod),
         {:ok, alb_act} <- Albergue.registrar_salida(albergue, doc) do
      nuevos_albergues = reemplazar_por_codigo(albergues, alb_act)
      GestorPersistencia.actualizar_lista(:albergues, nuevos_albergues)
      {:reply, {:ok, alb_act}, nuevos_albergues}
    else
      error -> {:reply, error, albergues}
    end
  end

  @impl true
  def handle_call(:reporte_ocupacion, _from, albergues) do
    {:reply, {:ok, Albergue.reporte_mayor_ocupacion(albergues)}, albergues}
  end

  @impl true
  def handle_call({:asociar_recurso, username, cod_alb, cod_rec}, _from, albergues) do
    with {:ok, _usuario} <- 
    GestorUsuarios.validar_y_registrar(username,
     :registrar_albergue, "asociar_recurso #{cod_rec} -> #{cod_alb}"),
         {:ok, albergue} <- buscar_por_codigo(albergues, cod_alb),
         {:ok, alb_act} <- Albergue.asociar_recurso(albergue, cod_rec) do
      nuevos_albergues = reemplazar_por_codigo(albergues, alb_act)
      GestorPersistencia.actualizar_lista(:albergues, nuevos_albergues)
      {:reply, {:ok, alb_act}, nuevos_albergues}
    else
      error -> {:reply, error, albergues}
    end
  end


@impl true
def handle_call({:asociar_necesidad, username, cod_alb, id_nec}, _from, albergues) do
  with {:ok, _usuario} <- 
  GestorUsuarios.validar_y_registrar(username,
   :registrar_albergue, "asociar_necesidad #{id_nec} -> #{cod_alb}"),
       {:ok, albergue} <- buscar_por_codigo(albergues, cod_alb),
       {:ok, alb_act} <- Albergue.asociar_necesidad(albergue, id_nec) do
    nuevos_albergues = reemplazar_por_codigo(albergues, alb_act)
    GestorPersistencia.actualizar_lista(:albergues, nuevos_albergues)
    {:reply, {:ok, alb_act}, nuevos_albergues}
  else
    error -> {:reply, error, albergues}
  end
end


  defp existe_codigo?([], _cod), do: false
  defp existe_codigo?([h | _t], cod) when h.codigo == cod, do: true
  defp existe_codigo?([_h | t], cod), do: existe_codigo?(t, cod)

  defp buscar_por_codigo([], cod), do: {:error, "albergue #{cod} no encontrado"}
  defp buscar_por_codigo([h | _t], cod) when h.codigo == cod, do: {:ok, h}
  defp buscar_por_codigo([_h | t], cod), do: buscar_por_codigo(t, cod)

  defp reemplazar_por_codigo([], _item), do: []
  defp reemplazar_por_codigo([h | t], item) when h.codigo == item.codigo, do: [item | t]
  defp reemplazar_por_codigo([h | t], item), do: [h | reemplazar_por_codigo(t, item)]

end
