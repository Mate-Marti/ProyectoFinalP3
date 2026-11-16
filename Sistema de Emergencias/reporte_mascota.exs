defmodule ReporteMascota do
  @moduledoc "Reporte de mascota perdida o encontrada."

  defstruct [:id, :tipo_reporte, :especie, :nombre, :caracteristicas, :color, :tamano, :zona, :contacto, estado: :activa]
  @tipos [:perdida, :encontrada]
  @estados [:activa, :posible_coincidencia, :resuelta]
  @transiciones %{
    activa: [:posible_coincidencia, :resuelta],
    posible_coincidencia: [:activa, :resuelta],
    resuelta: []
  }

  def crear_reporte(id, tipo, especie, nombre, carac, color, tamano, zona, contacto) do
    cond do
      tipo not in @tipos ->
        {:error, "Tipo de reporte inválido. Opciones: #{inspect(@tipos)}"}

      not texto_valido?(id) ->
        {:error, "El ID del reporte no puede estar vacío"}

      not texto_valido?(especie) ->
        {:error, "La especie no puede estar vacía"}

      not texto_valido?(color) ->
        {:error, "El color no puede estar vacío"}

      not texto_valido?(tamano) ->
        {:error, "El tamaño no puede estar vacío"}

      not texto_valido?(zona) ->
        {:error, "La zona no puede estar vacía"}

      not texto_valido?(contacto) ->
        {:error, "El contacto no puede estar vacío"}

      true ->
        nombre_limpio =
          if texto_valido?(nombre), do: String.trim(nombre), else: "desconocido"

        carac_limpias =
          if texto_valido?(carac), do: String.trim(carac), else: "sin detalles"

        {:ok,
         %ReporteMascota{
           id: String.trim(id),
           tipo_reporte: tipo,
           especie: String.downcase(String.trim(especie)),
           nombre: nombre_limpio,
           caracteristicas: carac_limpias,
           color: String.downcase(String.trim(color)),
           tamano: String.downcase(String.trim(tamano)),
           zona: String.trim(zona),
           contacto: String.trim(contacto)
         }}
    end
  end

  defp texto_valido?(val), do: is_binary(val) and String.trim(val) != ""
  # Un reporte resuelto no puede volver a cerrarse
  #map.fetch!(@transiciones, actual) devuelve la lista de estados a los que puede pasar desde el estado actual
  #el if verifica si el nuevo estado está en esa lista
  def cambiar_estado(%ReporteMascota{estado: actual} = r, nuevo) when nuevo in @estados do
    if nuevo in Map.fetch!(@transiciones, actual) do
      {:ok, %ReporteMascota{r | estado: nuevo}}
    else
      {:error, "transición no permitida: #{actual} -> #{nuevo}"}
    end
  end

  def cambiar_estado(_r, nuevo), do: {:error, "estado inválido: #{inspect(nuevo)}"}

  def tipos, do: @tipos
  def estados, do: @estados

  def filtrar_reportes([], _especie, _zona, _estado), do: []
  def filtrar_reportes([r | resto], especie, zona, estado) do
    cumple_especie = especie == nil or r.especie == especie
    cumple_zona = zona == nil or r.zona == zona
    cumple_estado = estado == nil or r.estado == estado

    if cumple_especie and cumple_zona and cumple_estado do
      [r | filtrar_reportes(resto, especie, zona, estado)]
    else
      filtrar_reportes(resto, especie, zona, estado)
    end
  end

 def buscar_coincidencias(reportes) do
    no_resueltos = Enum.filter(reportes, &(&1.estado != :resuelta))
    perdidas = separar_por_tipo(no_resueltos, :perdida)
    encontradas = separar_por_tipo(no_resueltos, :encontrada)
    emparejar_listas(perdidas, encontradas, [])
  end
  defp separar_por_tipo([], _tipo), do: []
  defp separar_por_tipo([r | resto], tipo) when r.tipo_reporte == tipo,
    do: [r | separar_por_tipo(resto, tipo)]

  defp separar_por_tipo([_r | resto], tipo), do: separar_por_tipo(resto, tipo)

  defp emparejar_listas([], _encontradas, acc), do: acc
  defp emparejar_listas([p | resto_p], encontradas, acc) do
    nuevos = evaluar_contra_encontradas(p, encontradas, acc)
    emparejar_listas(resto_p, encontradas, nuevos)
  end

  defp evaluar_contra_encontradas(_p, [], acc), do: acc

  defp evaluar_contra_encontradas(p, [e | resto_e], acc) do
    puntaje = calcular_puntaje(p, e)
    nuevo_acc = if puntaje >= 50, do: [{p.id, e.id, puntaje} | acc], else: acc
    evaluar_contra_encontradas(p, resto_e, nuevo_acc)
  end

  defp calcular_puntaje(p, e) do
    if p.especie != e.especie do
      0
    else
      puntos = 30
      puntos = if p.zona == e.zona, do: puntos + 25, else: puntos
      puntos = if p.color == e.color, do: puntos + 20, else: puntos
      puntos = if p.tamano == e.tamano, do: puntos + 15, else: puntos
     if String.downcase(p.nombre) != "desconocido" and
           String.downcase(p.nombre) == String.downcase(e.nombre),
         do: puntos + 10,
         else: puntos
    end
  end
# CORREGIDO: Verifica explícitamente que uno sea :perdida y otro :encontrada
  def confirmar_coincidencia(
        %ReporteMascota{tipo_reporte: :perdida} = perdida,
        %ReporteMascota{tipo_reporte: :encontrada} = encontrada
      ) do
    with {:ok, p_cerrado} <- cambiar_estado(perdida, :resuelta),
         {:ok, e_cerrado} <- cambiar_estado(encontrada, :resuelta) do
      {:ok, p_cerrado, e_cerrado}
    end
  end

  def confirmar_coincidencia(%ReporteMascota{tipo_reporte: t1}, %ReporteMascota{tipo_reporte: t2}) do
    {:error,
     "Para confirmar coincidencia el primer reporte debe ser :perdida y el segundo :encontrada (recibido: #{t1} y #{t2})"}
  end
end
