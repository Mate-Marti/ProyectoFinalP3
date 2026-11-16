defmodule Persistencia do
  @carpeta "resources"
  @archivo "emergencia.txt"

  def cargar_todo() do
    File.mkdir_p!(@carpeta)
    ruta = Path.join(@carpeta, @archivo)

    estado_vacio = %{
      usuarios: [],
      zonas: [],
      recursos: [],
      necesidades: [],
      albergues: [],
      personas: [],
      mensajes: [],
      mascotas: []
    }

    case File.read(ruta) do
      {:ok, contenido} ->
        contenido
        |> String.split("\n", trim: true)
        |> parsear_lineas_rec(estado_vacio)

      {:error, _} ->
        File.write!(ruta, "")
        estado_vacio
    end
  end

  def guardar_todo(estado) do
    File.mkdir_p!(@carpeta)
    ruta = Path.join(@carpeta, @archivo)

    contenido =
      ""
      |> agregar_bloque(estado.usuarios, &formatear_usuario/1)
      |> agregar_bloque(estado.zonas, &formatear_zona/1)
      |> agregar_bloque(estado.recursos, &formatear_recurso/1)
      |> agregar_bloque(estado.necesidades, &formatear_necesidad/1)
      |> agregar_bloque(estado.albergues, &formatear_albergue/1)
      |> agregar_bloque(estado.personas, &formatear_persona/1)
      |> agregar_bloque(estado.mensajes, &formatear_mensaje/1)
      |> agregar_bloque(estado.mascotas, &formatear_mascota/1)

    File.write!(ruta, contenido)
    :ok
  end

  #lectura recursiva de las lineas del archivo
  defp parsear_lineas_rec([], estado) do
    %{
      usuarios: Enum.reverse(estado.usuarios),
      zonas: Enum.reverse(estado.zonas),
      recursos: Enum.reverse(estado.recursos),
      necesidades: Enum.reverse(estado.necesidades),
      albergues: Enum.reverse(estado.albergues),
      personas: Enum.reverse(estado.personas),
      mensajes: Enum.reverse(estado.mensajes),
      mascotas: Enum.reverse(estado.mascotas)
    }
  end

  #parsear cada linea del archivo de persistencia y crear la estructura correspondiente
  defp parsear_lineas_rec([linea | resto], estado) do
    nuevo_estado =
      case String.split(String.trim(linea), "@") do
        ["USUARIO", u, p, nom, rol, zona] ->
          item = %Usuario{
            username: u,
            password: p,
            nombre_completo: nom,
            rol: String.to_atom(rol),
            zona_principal: zona,
            conectado: false
          }
          %{estado | usuarios: [item | estado.usuarios]}

        ["ZONA", cod, nom, niv, pers, sectores_txt] ->
          sectores =
            if sectores_txt == "",
              do: [],
              else: parsear_sectores_rec(String.split(sectores_txt, ";"), [])

          item = %Zona{
            codigo: cod,
            nombre: nom,
            nivel_afectacion: String.to_atom(niv),
            personas_afectadas: String.to_integer(pers),
            sectores: sectores
          }
          %{estado | zonas: [item | estado.zonas]}

        ["RECURSO", cod, nom, cat, cant, uni, ubi] ->
          item = %Recurso{
            codigo: cod,
            nombre: nom,
            categoria: String.to_atom(cat),
            cantidad: parsear_num(cant),
            unidad: uni,
            ubicacion: ubi
          }
          %{estado | recursos: [item | estado.recursos]}

        ["NECESIDAD", id, tipo, desc, cant, zona, prio, resp, est] ->
          item = %Necesidad{
            id: id,
            tipo: String.to_atom(tipo),
            descripcion: desc,
            cantidad: parsear_num(cant),
            zona: zona,
            prioridad: String.to_atom(prio),
            responsable: resp,
            estado: String.to_atom(est)
          }
          %{estado | necesidades: [item | estado.necesidades]}

       ["ALBERGUE", cod, nom, zona, cap, ocu, pers, recs, necs] ->
          lista_pers = if pers == "", do: [], else: String.split(pers, ",")
          lista_recs = if recs == "", do: [], else: String.split(recs, ",")
          lista_necs = if necs == "", do: [], else: String.split(necs, ",")

          item = %Albergue{
            codigo: cod,
            nombre: nom,
            zona: zona,
            capacidad_maxima: String.to_integer(cap),
            ocupacion_actual: String.to_integer(ocu),
            personas: lista_pers,
            recursos: lista_recs,
            necesidades: lista_necs
          }
          %{estado | albergues: [item | estado.albergues]}

        ["PERSONA", id, doc, nom, edad, zona, est] ->
          item = %PersonaAfectada{
            id: id,
            documento: doc,
            nombre: nom,
            edad: String.to_integer(edad),
            zona: zona,
            estado: String.to_atom(est)
          }
          %{estado | personas: [item | estado.personas]}

        ["MENSAJE", id, fecha, rem, dest, cont, est] ->
          {:ok, dt, _} = DateTime.from_iso8601(fecha)

          item = %MensajeFamiliar{
            id: id,
            fecha: dt,
            remitente: rem,
            destinatario: dest,
            contenido: cont,
            estado: String.to_atom(est)
          }
          %{estado | mensajes: [item | estado.mensajes]}

        ["MASCOTA", id, tipo, esp, nom, car, col, tam, zona, cont, est] ->
          item = %ReporteMascota{
            id: id,
            tipo_reporte: String.to_atom(tipo),
            especie: esp,
            nombre: nom,
            caracteristicas: car,
            color: col,
            tamano: tam,
            zona: zona,
            contacto: cont,
            estado: String.to_atom(est)
          }
          %{estado | mascotas: [item | estado.mascotas]}

        _ ->
          estado
      end

    parsear_lineas_rec(resto, nuevo_estado)
  end

  #estructuras de datos que se guardan en el archivo de persistencia
  defp agregar_bloque(acumulado, [], _formateador), do: acumulado

  defp agregar_bloque(acumulado, [item | resto], formateador) do
    agregar_bloque(acumulado <> formateador.(item) <> "\n", resto, formateador)
  end

  #se formatea cada esstructura con usando sus prefijos y se separan los campos con @
  defp formatear_usuario(u),
    do: "USUARIO@#{u.username}@#{u.password}@#{u.nombre_completo}@#{u.rol}@#{u.zona_principal}"

  defp formatear_zona(z) do
    sectores_txt = formatear_sectores_rec(z.sectores, []) |> Enum.join(";")
    "ZONA@#{z.codigo}@#{z.nombre}@#{z.nivel_afectacion}@#{z.personas_afectadas}@#{sectores_txt}"
  end

  defp formatear_sectores_rec([], acc), do: Enum.reverse(acc)

  defp formatear_sectores_rec([s | resto], acc) do
    puntos_txt = Enum.join(s.puntos_atencion, ",")
    item = "#{s.codigo}|#{s.nombre}|#{s.personas_afectadas}|#{puntos_txt}"
    formatear_sectores_rec(resto, [item | acc])
  end

  defp parsear_sectores_rec([], acc), do: Enum.reverse(acc)

  defp parsear_sectores_rec([s_txt | resto], acc) do
    case String.split(s_txt, "|") do
      [cod, nom, pers, puntos_txt] ->
        puntos = if puntos_txt == "", do: [], else: String.split(puntos_txt, ",")

        sector = %{
          codigo: cod,
          nombre: nom,
          personas_afectadas: String.to_integer(pers),
          puntos_atencion: puntos
        }

        parsear_sectores_rec(resto, [sector | acc])

      _ ->
        parsear_sectores_rec(resto, acc)
    end
  end

  defp formatear_recurso(r),
    do: "RECURSO@#{r.codigo}@#{r.nombre}@#{r.categoria}@#{r.cantidad}@#{r.unidad}@#{r.ubicacion}"

  defp formatear_necesidad(n),
    do: "NECESIDAD@#{n.id}@#{n.tipo}@#{n.descripcion}@#{n.cantidad}@#{n.zona}@#{n.prioridad}@#{n.responsable}@#{n.estado}"

  defp formatear_albergue(a),
    do: "ALBERGUE@#{a.codigo}@#{a.nombre}@#{a.zona}@#{a.capacidad_maxima}@#{a.ocupacion_actual}@#{Enum.join(a.personas, ",")}@#{Enum.join(a.recursos, ",")}@#{Enum.join(a.necesidades, ",")}"

  defp formatear_persona(p),
    do: "PERSONA@#{p.id}@#{p.documento}@#{p.nombre}@#{p.edad}@#{p.zona}@#{p.estado}"

  defp formatear_mensaje(m),
    do: "MENSAJE@#{m.id}@#{DateTime.to_iso8601(m.fecha)}@#{m.remitente}@#{m.destinatario}@#{m.contenido}@#{m.estado}"

  defp formatear_mascota(m),
    do: "MASCOTA@#{m.id}@#{m.tipo_reporte}@#{m.especie}@#{m.nombre}@#{m.caracteristicas}@#{m.color}@#{m.tamano}@#{m.zona}@#{m.contacto}@#{m.estado}"

  defp parsear_num(txt) do
    if String.contains?(txt, "."), do: String.to_float(txt), else: String.to_integer(txt)
  end
end
