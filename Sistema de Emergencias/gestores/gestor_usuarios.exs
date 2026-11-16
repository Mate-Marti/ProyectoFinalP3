defmodule GestorUsuarios do
  use GenServer

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def conectar(nodo \\ Node.self(), username, password,nombre_completo , rol, zona) do
    GenServer.call(destino(nodo), {:conectar, username, password, nombre_completo, rol, zona})
  end

  def desconectar(nodo \\ Node.self(), username) do
    GenServer.call(destino(nodo), {:desconectar, username})
  end

  def actividad_usuario(nodo \\ Node.self(), username) do
    GenServer.call(destino(nodo), {:actividad_usuario, username})
  end

  # Llamado internamente por los demás GenServers para validar permisos y registrar bitácora
  def validar_y_registrar(username, operacion, accion_log) do
    GenServer.call(__MODULE__, {:validar_y_registrar, username, operacion, accion_log})
  end

  defp destino(nodo), do: if(nodo == Node.self(), do: __MODULE__, else: {__MODULE__, nodo})

  @impl true
  def init(:ok) do
    {:ok, GestorPersistencia.obtener_lista(:usuarios)}
  end
@impl true
def handle_call({:conectar, username, password, nombre_completo, rol, zona}, _from, usuarios) do
  case Usuario.connect(username, password, nombre_completo, rol, zona, usuarios) do
    {:ok, nuevos_usuarios} ->
      GestorPersistencia.actualizar_lista(:usuarios, nuevos_usuarios)
      {:reply, {:ok, Usuario.buscar_usuario(nuevos_usuarios, username)}, nuevos_usuarios}

    {:error, motivo} ->
      {:reply, {:error, motivo}, usuarios}
  end
end

  @impl true
  def handle_call({:desconectar, username}, _from, usuarios) do
    nuevos_usuarios = Usuario.disconnect(username, usuarios)
    GestorPersistencia.actualizar_lista(:usuarios, nuevos_usuarios)
    {:reply, :ok, nuevos_usuarios}
  end

  @impl true
  def handle_call({:actividad_usuario, username}, _from, usuarios) do
    case Usuario.buscar_usuario(usuarios, username) do
      nil -> {:reply, {:error, "usuario #{username} no encontrado"}, usuarios}
      usuario -> {:reply, {:ok, usuario.historial_actividad}, usuarios}
    end
  end

  @impl true
  def handle_call({:validar_y_registrar, username, operacion, accion_log}, _from, usuarios) do
    case Usuario.buscar_usuario(usuarios, username) do
      nil ->
        {:reply, {:error, "usuario #{username} no encontrado"}, usuarios}

      usuario ->
        if Usuario.puede_ejecutar?(usuario, operacion) do
          usuario_act = Usuario.registrar_actividad(usuario, accion_log)
          nuevos_usuarios = reemplazar_usuario(usuarios, usuario_act)
          GestorPersistencia.actualizar_lista(:usuarios, nuevos_usuarios)
          {:reply, {:ok, usuario_act}, nuevos_usuarios}
        else
          {:reply, {:error, "usuario #{username} no conectado o sin permisos para #{operacion}"}, usuarios}
        end
    end
  end

  defp reemplazar_usuario([], _u), do: []
  defp reemplazar_usuario([h | t], u) when h.username == u.username, do: [u | t]
  defp reemplazar_usuario([h | t], u), do: [h | reemplazar_usuario(t, u)]
end
