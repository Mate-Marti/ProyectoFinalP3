defmodule GestorFamiliares do
  use GenServer

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def reportar_persona(nodo \\ Node.self(), username, id, doc, nom, edad, zona, est) do
    GenServer.call(destino(nodo), {:reportar_persona, username, id, doc, nom, edad, zona, est})
  end

  def cambiar_estado_persona(nodo \\ Node.self(), username, doc, nuevo_est) do
    GenServer.call(destino(nodo), {:cambiar_estado_persona, username, doc, nuevo_est})
  end

  def buscar_personas(nodo \\ Node.self(), criterio) do
    GenServer.call(destino(nodo), {:buscar_personas, criterio})
  end

  def listar_personas(nodo \\ Node.self()) do
    GenServer.call(destino(nodo), :listar_personas)
  end

  def enviar_mensaje(nodo \\ Node.self(), username, id, destinatario, contenido) do
    GenServer.call(destino(nodo), {:enviar_mensaje, username, id, destinatario, contenido})
  end

  def marcar_entregado(nodo \\ Node.self(), username, id_msg) do
    GenServer.call(destino(nodo), {:marcar_entregado, username, id_msg})
  end

  def listar_mensajes(nodo \\ Node.self(), destinatario) do
    GenServer.call(destino(nodo), {:listar_mensajes, destinatario})
  end

  def todos_los_mensajes(nodo \\ Node.self()) do
    GenServer.call(destino(nodo), :todos_los_mensajes)
  end

  defp destino(nodo), do: if(nodo == Node.self(), do: __MODULE__, else: {__MODULE__, nodo})

  @impl true
  def init(:ok) do
    estado = %{
      personas: GestorPersistencia.obtener_lista(:personas),
      mensajes: GestorPersistencia.obtener_lista(:mensajes)
    }
    {:ok, estado}
  end

  @impl true
  def handle_call({:reportar_persona, username, id, doc, nom, edad, zona, est}, _from, estado) do
    with {:ok, _usuario} <- GestorUsuarios.validar_y_registrar(username, :reportar_persona, "reportar_persona #{doc}"),
         false <- existe_id?(estado.personas, id),
         {:ok, persona} <- PersonaAfectada.crear_afectada(id, doc, nom, edad, zona, est) do
      GestorZonas.asociar_elemento(zona, :reportes, id)
      nuevas_personas = [persona | estado.personas]
      GestorPersistencia.actualizar_lista(:personas, nuevas_personas)
      {:reply, {:ok, persona}, %{estado | personas: nuevas_personas}}
    else
      true -> {:reply, {:error, "el id de persona #{id} ya existe"}, estado}
      error -> {:reply, error, estado}
    end
  end

  @impl true
  def handle_call({:cambiar_estado_persona, username, doc, nuevo_est}, _from, estado) do
    with {:ok, _usuario} <- GestorUsuarios.validar_y_registrar(username, :reportar_persona, "estado_persona #{doc} -> #{nuevo_est}"),
         {:ok, persona} <- buscar_por_doc(estado.personas, doc),
         {:ok, pers_act} <- PersonaAfectada.cambiar_estado(persona, nuevo_est) do
      nuevas_personas = reemplazar_por_id(estado.personas, pers_act)
      GestorPersistencia.actualizar_lista(:personas, nuevas_personas)
      {:reply, {:ok, pers_act}, %{estado | personas: nuevas_personas}}
    else
      error -> {:reply, error, estado}
    end
  end

  @impl true
  def handle_call({:buscar_personas, criterio}, _from, estado) do
    {:reply, {:ok, PersonaAfectada.buscar_personas(estado.personas, criterio)}, estado}
  end

  @impl true
  def handle_call(:listar_personas, _from, estado) do
    {:reply, {:ok, estado.personas}, estado}
  end

  @impl true
  def handle_call({:enviar_mensaje, username, id, destinatario, contenido}, _from, estado) do
    with {:ok, _usuario} <- GestorUsuarios.validar_y_registrar(username, :enviar_mensaje, "enviar_mensaje #{id}"),
         false <- existe_id?(estado.mensajes, id),
         {:ok, msg} <- MensajeFamiliar.crear_mensaje(id, username, destinatario, contenido) do
      nuevos_mensajes = [msg | estado.mensajes]
      GestorPersistencia.actualizar_lista(:mensajes, nuevos_mensajes)
      {:reply, {:ok, msg}, %{estado | mensajes: nuevos_mensajes}}
    else
      true -> {:reply, {:error, "el id de mensaje #{id} ya existe"}, estado}
      error -> {:reply, error, estado}
    end
  end

  @impl true
  def handle_call({:marcar_entregado, username, id_msg}, _from, estado) do
    with {:ok, _usuario} <- GestorUsuarios.validar_y_registrar(username, :enviar_mensaje, "entregar_mensaje #{id_msg}"),
         {:ok, msg} <- buscar_por_id(estado.mensajes, id_msg),
         {:ok, msg_act} <- MensajeFamiliar.marcar_entregado(msg) do
      nuevos_mensajes = reemplazar_por_id(estado.mensajes, msg_act)
      GestorPersistencia.actualizar_lista(:mensajes, nuevos_mensajes)
      {:reply, {:ok, msg_act}, %{estado | mensajes: nuevos_mensajes}}
    else
      error -> {:reply, error, estado}
    end
  end

  @impl true
  def handle_call({:listar_mensajes, destinatario}, _from, estado) do
    {:reply, {:ok, MensajeFamiliar.listar_mensajes(estado.mensajes, destinatario)}, estado}
  end

  @impl true
  def handle_call(:todos_los_mensajes, _from, estado) do
    {:reply, {:ok, estado.mensajes}, estado}
  end

  defp existe_id?([], _id), do: false
  defp existe_id?([h | _t], id) when h.id == id, do: true
  defp existe_id?([_h | t], id), do: existe_id?(t, id)

  defp buscar_por_id([], id), do: {:error, "registro #{id} no encontrado"}
  defp buscar_por_id([h | _t], id) when h.id == id, do: {:ok, h}
  defp buscar_por_id([_h | t], id), do: buscar_por_id(t, id)

  defp buscar_por_doc([], doc), do: {:error, "persona con documento #{doc} no encontrada"}
  defp buscar_por_doc([h | _t], doc) when h.documento == doc, do: {:ok, h}
  defp buscar_por_doc([_h | t], doc), do: buscar_por_doc(t, doc)

  defp reemplazar_por_id([], _item), do: []
  defp reemplazar_por_id([h | t], item) when h.id == item.id, do: [item | t]
  defp reemplazar_por_id([h | t], item), do: [h | reemplazar_por_id(t, item)]
end
