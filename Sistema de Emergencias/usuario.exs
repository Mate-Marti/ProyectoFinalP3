defmodule Usuario do

  defstruct [:username, :password, :nombre_completo, :rol, :zona_principal, conectado: false, historial_actividad: []]

  def crear_usuario(username, password, nombre_completo, rol, zona) when rol in [:ciudadano, :voluntario, :coordinador, :administrador] do
    %Usuario{
      username: username,
      password: password,
      nombre_completo: nombre_completo,
      rol: rol,
      zona_principal: zona,
      conectado: false,
      historial_actividad: []
    }
  end

  #se busca al usuario, si existe retorna un mapa
  def buscar_usuario([], _username), do: nil
  def buscar_usuario([usuario | _resto], username) when usuario.username == username, do: usuario
  def buscar_usuario([_usuario | resto], username), do: buscar_usuario(resto, username)


  #coneccion del usuario
  def connect(username, password, rol, zona, lista_usuarios) do
    usuario_existente = buscar_usuario(lista_usuarios, username)

    cond do
      #si no existe se registra y entra como conectado
      usuario_existente == nil ->
        nuevo_usuario = %{crear_usuario(username, password, username, rol, zona) | conectado: true}
        IO.puts("usuario registrado y conectado")
        lista_usuarios ++ [nuevo_usuario]

      #si existe se valida la contraseña
      usuario_existente.password == password ->
        IO.puts("bienvenido #{username}")
        actualizar_estado_conexion(lista_usuarios, username, true)

      #si la contraseña es incorrecta
      true ->
        IO.puts("error, la contraseña es incorrecta #{username}.")
        lista_usuarios
    end
  end

  #desconectar al ususario
  def disconnect(username, lista_usuarios) do
    usuario = buscar_usuario(lista_usuarios, username)

    if usuario != nil do
      IO.puts("usuario #{username} desconectado")
      actualizar_estado_conexion(lista_usuarios, username, false)
    else
      IO.puts("error, el usuario #{username} no existe")
      lista_usuarios
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
  def puede_ejecutar?(%Usuario{rol: :administrador}, operacion), do: true

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
      :emparejaar_mascota,
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
      :emparejaar_mascota,
      :ingreso_albergue,
      :salida_albergue,
      :consultar
    ],
    do: true

  #funcion cuando el usuario es ciudadano puede ejecutar ciertas operaciones
  def puede_ejecutar?(%Usuario{rol: :ciudadano}, operacion)
    when operacion in [
      :reportar_necesidad,
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
