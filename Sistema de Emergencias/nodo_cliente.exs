Code.require_file("util.ex")
Code.require_file("usuario.exs")
Code.require_file("zona.exs")
Code.require_file("recurso.exs")
Code.require_file("necesidad.exs")
Code.require_file("albergue.exs")
Code.require_file("persona_afectada.exs")
Code.require_file("Mensaje_Familiar.exs")
Code.require_file("reporte_mascota.exs")
Code.require_file("gestores/gestor_usuarios.exs", __DIR__)
Code.require_file("gestores/gestor_zonas.exs", __DIR__)
Code.require_file("gestores/gestor_recursos.exs", __DIR__)
Code.require_file("gestores/gestor_necesidades.exs", __DIR__)
Code.require_file("gestores/gestor_albergues.exs", __DIR__)
Code.require_file("gestores/gestor_familiares.exs", __DIR__)
Code.require_file("gestores/gestor_mascotas.exs", __DIR__)

defmodule NodoCliente do
  @nodo_servidor :servidor@localhost

  def main() do
    case Node.connect(@nodo_servidor) do
      true ->
        Util.mostrar_mensaje("Conectado exitosamente al nodo #{@nodo_servidor}")
        Util.mostrar_mensaje("Escribe 'ayuda' para ver los comandos disponibles.\n")
        ciclo_cli(nil)

      false ->
        Util.mostrar_error("No se pudo conectar con #{@nodo_servidor}. Verifica el nombre del nodo y la cookie.")
    end
  end

  defp ciclo_cli(usuario_actual) do
    prompt = if usuario_actual == nil, do: "[sin_sesion]> ", else: "[#{usuario_actual}]> "
    linea = Util.ingresar(prompt, :texto)
    tokens = tokenizar(linea)

    case ejecutar_comando(tokens, usuario_actual) do
      :salir ->
        if usuario_actual != nil,
          do: GestorUsuarios.desconectar(@nodo_servidor, usuario_actual)

        Util.mostrar_mensaje("Sesión finalizada.")

      {:nuevo_usuario, nuevo_user} ->
        ciclo_cli(nuevo_user)

      :continuar ->
        ciclo_cli(usuario_actual)
    end
  end

  defp ejecutar_comando([], _user), do: :continuar

  defp ejecutar_comando(["ayuda"], _user) do
    Util.mostrar_mensaje("""

      Comandos que se pueden usar junto con sus parámetros:


      conectar <usuario> <contrasena> <rol> <zona>
      desconectar
      actividad <usuario>

      registrar_zona <codigo> "<nombre>" <nivel> [personas]
      agregar_sector <cod_zona> <cod_sector> "<nombre>" [personas]
      agregar_punto <cod_zona> <cod_sector> "<punto_atencion>"
      consultar_zona <cod_zona>
      estadisticas_zona <cod_zona>

      registrar_necesidad <id> <tipo> <cantidad> <prioridad> <zona> "<descripcion>"
      listar_necesidades
      necesidades_pendientes
      estado_necesidad <id_necesidad> <nuevo_estado>

      registrar_recurso <codigo> "<nombre>" <categoria> <cantidad> <unidad> <ubicacion>
      entrada_recurso <codigo> <cantidad>
      listar_recursos
      recursos_criticos [umbral]
      asignar_recurso <id_necesidad> <cod_o_categoria> <cantidad>
      transferir_recurso <cod_recurso> <origen> <destino> <cantidad>

      reportar_persona <id> <documento> "<nombre>" <edad> <zona> <estado>
      estado_persona <documento> <nuevo_estado>
      buscar_persona "<criterio>"

      enviar_mensaje <id> <destinatario> "<contenido>"
      entregar_mensaje <id_mensaje>
      listar_mensajes <destinatario>

      reportar_mascota <id> <perdida|encontrada> <especie> "<nombre>" "<caracteristicas>" <color> <tamano> <zona> <contacto>
      listar_mascotas
      buscar_coincidencias
      confirmar_mascota <id_perdida> <id_encontrada>

      registrar_albergue <codigo> "<nombre>" <zona> <capacidad>
      consultar_albergue <codigo>
      ingreso_albergue <cod_albergue> <documento>
      salida_albergue <cod_albergue> <documento>
      reporte_albergues

      resumen
      salir
    """)

    :continuar
  end

  defp ejecutar_comando(["salir"], _user), do: :salir

  #usuarios
  defp ejecutar_comando(["conectar", user, pass, rol, zona], _actual) do
    respuesta = GestorUsuarios.conectar(@nodo_servidor, user, pass, String.to_atom(rol), zona)
    imprimir_respuesta(respuesta)
    {:nuevo_usuario, user}
  end

  defp ejecutar_comando(["desconectar"], nil) do
    Util.mostrar_error("No hay ningún usuario conectado.")
    :continuar
  end

  defp ejecutar_comando(["desconectar"], user) do
    GestorUsuarios.desconectar(@nodo_servidor, user)
    Util.mostrar_mensaje("Usuario #{user} desconectado.")
    {:nuevo_usuario, nil}
  end

  defp ejecutar_comando(["actividad", user], _actual) do
    imprimir_respuesta(GestorUsuarios.actividad_usuario(@nodo_servidor, user))
    :continuar
  end

  #zonas
  defp ejecutar_comando(["registrar_zona", cod, nom, nivel], user),
    do: ejecutar_comando(["registrar_zona", cod, nom, nivel, "0"], user)

  defp ejecutar_comando(["registrar_zona", cod, nom, nivel, pers], user) do
    with {:ok, cant_pers} <- a_entero(pers) do
      imprimir_respuesta(
        GestorZonas.registrar_zona(@nodo_servidor, user, cod, nom, String.to_atom(nivel), cant_pers)
      )
    else
      err -> imprimir_respuesta(err)
    end

    :continuar
  end

  defp ejecutar_comando(["agregar_sector", cod_z, cod_s, nom], user),
    do: ejecutar_comando(["agregar_sector", cod_z, cod_s, nom, "0"], user)

  defp ejecutar_comando(["agregar_sector", cod_z, cod_s, nom, pers], user) do
    with {:ok, cant_pers} <- a_entero(pers) do
      imprimir_respuesta(
        GestorZonas.agregar_sector(@nodo_servidor, user, cod_z, cod_s, nom, cant_pers)
      )
    else
      err -> imprimir_respuesta(err)
    end

    :continuar
  end

  defp ejecutar_comando(["agregar_punto", cod_z, cod_s, punto], user) do
    imprimir_respuesta(
      GestorZonas.agregar_punto_atencion(@nodo_servidor, user, cod_z, cod_s, punto)
    )

    :continuar
  end

  defp ejecutar_comando(["consultar_zona", cod_z], _user) do
    imprimir_respuesta(GestorZonas.consultar_zona(@nodo_servidor, cod_z))
    :continuar
  end

  defp ejecutar_comando(["estadisticas_zona", cod_z], _user) do
    imprimir_respuesta(GestorZonas.estadisticas_zona(@nodo_servidor, cod_z))
    :continuar
  end

  #necesidades
  defp ejecutar_comando(["registrar_necesidad", id, tipo, cant, prio, zona, desc], user) do
    with {:ok, cantidad} <- a_numero(cant) do
      imprimir_respuesta(
        GestorNecesidades.registrar_necesidad(
          @nodo_servidor,
          user,
          id,
          String.to_atom(tipo),
          desc,
          cantidad,
          zona,
          String.to_atom(prio)
        )
      )
    else
      err -> imprimir_respuesta(err)
    end

    :continuar
  end

  defp ejecutar_comando(["listar_necesidades"], _user) do
    imprimir_respuesta(GestorNecesidades.listar_necesidades(@nodo_servidor))
    :continuar
  end

  defp ejecutar_comando(["necesidades_pendientes"], _user) do
    imprimir_respuesta(
      GestorNecesidades.listar_necesidades(@nodo_servidor, nil, nil, nil, :pendiente)
    )

    :continuar
  end

  defp ejecutar_comando(["estado_necesidad", id_nec, nuevo_est], user) do
    imprimir_respuesta(
      GestorNecesidades.cambiar_estado(@nodo_servidor, user, id_nec, String.to_atom(nuevo_est))
    )

    :continuar
  end

  defp ejecutar_comando(["asignar_recurso", id_nec, cod_o_cat, cant], user) do
    with {:ok, cantidad} <- a_numero(cant) do
      objetivo =
        if String.starts_with?(cod_o_cat, "R"),
          do: cod_o_cat,
          else: String.to_atom(cod_o_cat)

      imprimir_respuesta(
        GestorNecesidades.asignar_recurso(@nodo_servidor, user, id_nec, objetivo, cantidad)
      )
    else
      err -> imprimir_respuesta(err)
    end

    :continuar
  end

  #recursos
  defp ejecutar_comando(["registrar_recurso", cod, nom, cat, cant, uni, ubi], user) do
    with {:ok, cantidad} <- a_numero(cant) do
      imprimir_respuesta(
        GestorRecursos.registrar_recurso(
          @nodo_servidor,
          user,
          cod,
          nom,
          String.to_atom(cat),
          cantidad,
          uni,
          ubi
        )
      )
    else
      err -> imprimir_respuesta(err)
    end

    :continuar
  end

  defp ejecutar_comando(["entrada_recurso", cod, cant], user) do
    with {:ok, cantidad} <- a_numero(cant) do
      imprimir_respuesta(GestorRecursos.entrada_recurso(@nodo_servidor, user, cod, cantidad))
    else
      err -> imprimir_respuesta(err)
    end

    :continuar
  end

  defp ejecutar_comando(["listar_recursos"], _user) do
    imprimir_respuesta(GestorRecursos.listar_recursos(@nodo_servidor))
    :continuar
  end

  defp ejecutar_comando(["recursos_criticos"], user),
    do: ejecutar_comando(["recursos_criticos", "10"], user)

  defp ejecutar_comando(["recursos_criticos", umbral], _user) do
    with {:ok, valor} <- a_numero(umbral) do
      imprimir_respuesta(GestorRecursos.recursos_criticos(@nodo_servidor, valor))
    else
      err -> imprimir_respuesta(err)
    end

    :continuar
  end

  defp ejecutar_comando(["transferir_recurso", cod, origen, destino, cant], user) do
    with {:ok, cantidad} <- a_numero(cant) do
      imprimir_respuesta(
        GestorRecursos.transferir_recurso(@nodo_servidor, user, cod, origen, destino, cantidad)
      )
    else
      err -> imprimir_respuesta(err)
    end

    :continuar
  end

  #personas y mensajes
  defp ejecutar_comando(["reportar_persona", id, doc, nom, edad, zona, est], user) do
    with {:ok, edad_num} <- a_entero(edad) do
      imprimir_respuesta(
        GestorFamiliares.reportar_persona(
          @nodo_servidor,
          user,
          id,
          doc,
          nom,
          edad_num,
          zona,
          String.to_atom(est)
        )
      )
    else
      err -> imprimir_respuesta(err)
    end

    :continuar
  end

  defp ejecutar_comando(["estado_persona", doc, nuevo_est], user) do
    imprimir_respuesta(
      GestorFamiliares.cambiar_estado_persona(@nodo_servidor, user, doc, String.to_atom(nuevo_est))
    )

    :continuar
  end

  defp ejecutar_comando(["buscar_persona", criterio], _user) do
    imprimir_respuesta(GestorFamiliares.buscar_personas(@nodo_servidor, criterio))
    :continuar
  end

  defp ejecutar_comando(["enviar_mensaje", id, dest, contenido], user) do
    imprimir_respuesta(GestorFamiliares.enviar_mensaje(@nodo_servidor, user, id, dest, contenido))
    :continuar
  end

  defp ejecutar_comando(["entregar_mensaje", id_msg], user) do
    imprimir_respuesta(GestorFamiliares.marcar_entregado(@nodo_servidor, user, id_msg))
    :continuar
  end

  defp ejecutar_comando(["listar_mensajes", dest], _user) do
    imprimir_respuesta(GestorFamiliares.listar_mensajes(@nodo_servidor, dest))
    :continuar
  end

  #mascotas
  defp ejecutar_comando(["reportar_mascota", id, tipo, esp, nom, car, col, tam, zona, cont], user) do
    imprimir_respuesta(
      GestorMascotas.reportar_mascota(
        @nodo_servidor,
        user,
        id,
        String.to_atom(tipo),
        esp,
        nom,
        car,
        col,
        tam,
        zona,
        cont
      )
    )

    :continuar
  end

  defp ejecutar_comando(["listar_mascotas"], _user) do
    imprimir_respuesta(GestorMascotas.listar_mascotas(@nodo_servidor))
    :continuar
  end

  defp ejecutar_comando(["buscar_coincidencias"], _user) do
    imprimir_respuesta(GestorMascotas.buscar_coincidencias(@nodo_servidor))
    :continuar
  end

  defp ejecutar_comando(["confirmar_mascota", id_p, id_e], user) do
    imprimir_respuesta(GestorMascotas.confirmar_coincidencia(@nodo_servidor, user, id_p, id_e))
    :continuar
  end

  #albergues
  defp ejecutar_comando(["registrar_albergue", cod, nom, zona, cap], user) do
    with {:ok, capacidad} <- a_entero(cap) do
      imprimir_respuesta(
        GestorAlbergues.registrar_albergue(@nodo_servidor, user, cod, nom, zona, capacidad)
      )
    else
      err -> imprimir_respuesta(err)
    end

    :continuar
  end

  defp ejecutar_comando(["consultar_albergue", cod], _user) do
    imprimir_respuesta(GestorAlbergues.consultar_albergue(@nodo_servidor, cod))
    :continuar
  end

  defp ejecutar_comando(["ingreso_albergue", cod, doc], user) do
    imprimir_respuesta(GestorAlbergues.ingreso_albergue(@nodo_servidor, user, cod, doc))
    :continuar
  end

  defp ejecutar_comando(["salida_albergue", cod, doc], user) do
    imprimir_respuesta(GestorAlbergues.salida_albergue(@nodo_servidor, user, cod, doc))
    :continuar
  end

  defp ejecutar_comando(["reporte_albergues"], _user) do
    imprimir_respuesta(GestorAlbergues.reporte_ocupacion(@nodo_servidor))
    :continuar
  end

  #resumen consultando todos los genserveres
  defp ejecutar_comando(["resumen"], _user) do
    {:ok, zonas} = GestorZonas.listar_zonas(@nodo_servidor)
    {:ok, recursos} = GestorRecursos.listar_recursos(@nodo_servidor)
    {:ok, necesidades} = GestorNecesidades.listar_necesidades(@nodo_servidor)
    {:ok, albergues} = GestorAlbergues.reporte_ocupacion(@nodo_servidor)
    {:ok, personas} = GestorFamiliares.listar_personas(@nodo_servidor)
    {:ok, mensajes} = GestorFamiliares.todos_los_mensajes(@nodo_servidor)
    {:ok, mascotas} = GestorMascotas.listar_mascotas(@nodo_servidor)

    resumen = %{
      total_zonas: length(zonas),
      recursos_disponibles: recursos,
      necesidades_ordenadas: necesidades,
      albergues_ocupacion: albergues,
      personas: personas,
      mensajes: mensajes,
      mascotas: mascotas
    }

    IO.inspect(resumen, pretty: true)
    :continuar
  end

  defp ejecutar_comando(_otro, _user) do
    Util.mostrar_error("Comando no reconocido o parámetros incompletos. Escribe 'ayuda'.")
    :continuar
  end

  defp imprimir_respuesta({:ok, datos}), do: IO.inspect(datos, pretty: true)
  defp imprimir_respuesta({:error, razon}), do: Util.mostrar_error("Error: #{razon}")
  defp imprimir_respuesta(otro), do: IO.inspect(otro, pretty: true)

  defp a_entero(txt) do
    try do
      {:ok, String.to_integer(txt)}
    rescue
      ArgumentError -> {:error, "se esperaba un número entero, se recibió: #{txt}"}
    end
  end

  defp a_numero(txt) do
    try do
      valor =
        if String.contains?(txt, "."),
          do: String.to_float(txt),
          else: String.to_integer(txt)

      {:ok, valor}
    rescue
      ArgumentError -> {:error, "se esperaba un número válido, se recibió: #{txt}"}
    end
  end

  defp tokenizar(cadena), do: tokenizar_rec(String.trim(cadena), false, "", [])

  defp tokenizar_rec("", _en_comillas, "", acc), do: Enum.reverse(acc)
  defp tokenizar_rec("", _en_comillas, actual, acc), do: Enum.reverse([actual | acc])

  defp tokenizar_rec(<<"\"", resto::binary>>, en_comillas, actual, acc) do
    tokenizar_rec(resto, not en_comillas, actual, acc)
  end

  defp tokenizar_rec(<<" ", resto::binary>>, false, "", acc) do
    tokenizar_rec(resto, false, "", acc)
  end

  defp tokenizar_rec(<<" ", resto::binary>>, false, actual, acc) do
    tokenizar_rec(resto, false, "", [actual | acc])
  end

  defp tokenizar_rec(<<c::utf8, resto::binary>>, en_comillas, actual, acc) do
    tokenizar_rec(resto, en_comillas, actual <> <<c::utf8>>, acc)
  end
end

NodoCliente.main()
