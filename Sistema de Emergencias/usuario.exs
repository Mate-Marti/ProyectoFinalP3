defmodule Usuario do

  defstruct [:username, :password, :nombre_completo, :rol, :zona_principal, conectado: false, historial_actividad: []]

  @roles [:administrador, :coordinador, :voluntario, :ciudadano]

 def crear_usuario(username, password, nombre_completo, rol, zona) when rol in @roles do
  {:ok,
   %Usuario{
     username: username,
     password: password,
     nombre_completo: nombre_completo,
     rol: rol,
     zona_principal: zona,
     conectado: false,
     historial_actividad: []
   }}
end
# Validamos que todos los campos de texto sean binarios no vacíos y el rol sea válido
  def crear_usuario(username, password, nombre_completo, rol, zona) do
    with :ok <- validar_texto(username, "username"),
         :ok <- validar_texto(password, "contraseña"),
         :ok <- validar_texto(nombre_completo, "nombre completo"),
         :ok <- validar_texto(zona, "zona principal"),
         {:ok, rol_atomo} <- validar_rol(rol) do
      {:ok,
       %Usuario{
         username: String.trim(username),
         password: password,
         nombre_completo: String.trim(nombre_completo),
         rol: rol_atomo,
         zona_principal: String.trim(zona),
         conectado: false,
         historial_actividad: []
       }}
    end
  end
  # Funciones privadas de validación (retornan :ok o {:error, motivo})
  defp validar_texto(valor, campo) when is_binary(valor) do
    if String.trim(valor) == "" do
      {:error, "El campo '#{campo}' no puede estar vacío"}
    else
      :ok
    end
  end
  defp validar_texto(_, campo), do: {:error, "El campo '#{campo}' debe ser una cadena de texto"}

  defp validar_rol(rol) when rol in @roles, do: {:ok, rol}

  defp validar_rol(rol) when is_binary(rol) do
    rol_atomo =
      case String.downcase(String.trim(rol)) do
        "administrador" -> :administrador
        "coordinador" -> :coordinador
        "voluntario" -> :voluntario
        "ciudadano" -> :ciudadano
        _ -> nil
      end

    if rol_atomo,
      do: {:ok, rol_atomo},
      else: {:error, "Rol inválido: '#{rol}'. Opciones válidas: #{inspect(@roles)}"}
  end

  defp validar_rol(rol),
    do: {:error, "Rol inválido: #{inspect(rol)}. Opciones válidas: #{inspect(@roles)}"}
  #se busca al usuario, si existe retorna un mapa
  def buscar_usuario([], _username), do: nil
  def buscar_usuario([usuario | _resto], username) when usuario.username == username, do: usuario
  def buscar_usuario([_usuario | resto], username), do: buscar_usuario(resto, username)


 # Conexión del usuario
  def connect(username, password, nombre_completo, rol, zona, lista_usuarios) do
    with :ok <- validar_texto(username, "username"),
         :ok <- validar_texto(password, "contraseña") do
      username_limpio = String.trim(username)
      usuario_existente = buscar_usuario(lista_usuarios, username_limpio)

      cond do
        usuario_existente == nil ->
          with {:ok, usuario} <- crear_usuario(username_limpio, password, nombre_completo, rol, zona) do
            nuevo_usuario = %{usuario | conectado: true}
            {:ok, lista_usuarios ++ [nuevo_usuario]}
          end

        usuario_existente.password == password ->
          {:ok, actualizar_estado_conexion(lista_usuarios, username_limpio, true)}

        true ->
          {:error, "Contraseña incorrecta para el usuario '#{username_limpio}'"}
      end
    end
  end

  # CORREGIDO: Ahora es una función pura de dominio que retorna {:ok, lista} o {:error, motivo}
  # sin hacer IO.puts dentro de la lógica de negocio.
  def disconnect(username, lista_usuarios) do
    with :ok <- validar_texto(username, "username") do
      case buscar_usuario(lista_usuarios, String.trim(username)) do
        nil ->
          {:error, "El usuario '#{username}' no existe"}

        %Usuario{conectado: false} ->
          {:error, "El usuario '#{username}' ya se encontraba desconectado"}

        %Usuario{conectado: true} ->
          {:ok, actualizar_estado_conexion(lista_usuarios, String.trim(username), false)}
      end
    end
  end
  #funciones auxiliares para csmbiar la coneccion de usuario especifico sin afectar el resto
  defp actualizar_estado_conexion([], _username, _estado), do: []

  #cuando encuentra al usuario le cambia el estado lo pone con el resto
  defp actualizar_estado_conexion([usuario | resto], username, estado) when usuario.username == username do
    [%{usuario | conectado: estado} | resto]
  end

  #si no es el usuario que se busca lo deja igual y sigue buscando
  defp actualizar_estado_conexion([usuario | resto], username, estado) do
    [usuario | actualizar_estado_conexion(resto, username, estado)]
  end

  # registrar la actividad realizada por cada usuario

  #funcion cuando el usuario esta desconectado no puede ejecutar ninguna operacion
  def puede_ejecutar?(%Usuario{conectado: false}, _operacion), do: false

  #funcion cuando el usuario es administrador puede ejecutar cualquier operacion
  def puede_ejecutar?(%Usuario{rol: :administrador}, _operacion), do: true

  #funcion cuando el usuario es coordinador puede ejecutar ciertas operaciones
  def puede_ejecutar?(%Usuario{rol: :coordinador}, operacion)
    when operacion in [
      :registrar_zona,
      :registrar_necesidad,
      :asignar_recursos,
      :registrar_recursos,
      :transferir_recursos,
      :reportar_persona,
      :enviar_mensaje,
      :reportar_mascota,
      :emparejar_mascota,
      :registrar_albergue,
      :ingreso_albergue,
      :salida_albergue,
      :consultar
    ],
    do: true

  #funcion cuando el usuario es voluntario puede ejecutar ciertas operaciones
  def puede_ejecutar?(%Usuario{rol: :voluntario}, operacion)
    when operacion in [
      :registrar_necesidad,
      :reportar_persona,
      :enviar_mensaje,
      :reportar_mascota,
      :emparejar_mascota,
      :ingreso_albergue,
      :salida_albergue,
      :consultar
    ],
    do: true

  #funcion cuando el usuario es ciudadano puede ejecutar ciertas operaciones
  def puede_ejecutar?(%Usuario{rol: :ciudadano}, operacion)
    when operacion in [
      :registrar_necesidad,
      :reportar_persona,
      :enviar_mensaje,
      :reportar_mascota,
      :consultar
    ],
    do: true

  #funcion cuando el usuario no tiene rol definido no puede ejecutar ninguna operacion
  def puede_ejecutar?(_usuario, _operacion), do: false

  def registrar_actividad(%Usuario{} = usuario, actividad) do
    registro = {actividad, DateTime.utc_now()}
    %Usuario{usuario | historial_actividad: [registro | usuario.historial_actividad]}
  end

end
