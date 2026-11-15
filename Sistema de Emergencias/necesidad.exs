defmodule Necesidad do
  @moduledoc "Solicitud de ayuda. La prioridad se usa para ordenar la atención."

  defstruct [:id, :tipo, :descripcion, :cantidad, :zona, :prioridad, :responsable, estado: :pendiente]

  @tipos [:agua, :alimentos, :medicamentos, :primeros_auxilios, :refugio, :transporte, :rescate, :otra]

  # Peso de cada prioridad: mientras más alto el número, más urgente
  @peso_prioridad %{critica: 3, alta: 2, media: 1, baja: 0}

  # Lista de prioridades de más urgente a menos urgente, calculada desde el mapa:
  # [:critica, :alta, :media, :baja]
  @prioridades Enum.sort_by(Map.keys(@peso_prioridad), &@peso_prioridad[&1], :desc)

  @estados [:pendiente, :asignada, :en_atencion, :atendida, :cancelada]

  # Transiciones válidas: estado actual => estados a los que puede pasar
  @transiciones %{
    pendiente: [:asignada, :cancelada],
    asignada: [:en_atencion, :cancelada],
    en_atencion: [:atendida, :cancelada],
    atendida: [],
    cancelada: []
  }

  # not in verifica que el elemento no esté en la lista
  def crear_necesidad(id, tipo, descripcion, cantidad, zona, prioridad, responsable) do
    cond do
      tipo not in @tipos ->
        {:error, "tipo inválido. Opciones: #{inspect(@tipos)}"}

      prioridad not in @prioridades ->
        {:error, "prioridad inválida. Opciones: #{inspect(@prioridades)}"}

      not (is_number(cantidad) and cantidad > 0) ->
        {:error, "la cantidad debe ser mayor que 0"}

      true ->
        {:ok,
         %Necesidad{
           id: id,
           tipo: tipo,
           descripcion: descripcion,
           cantidad: cantidad,
           zona: zona,
           prioridad: prioridad,
           responsable: responsable
         }}
    end
  end

  # No se puede cerrar dos veces ni saltarse pasos (ej: pendiente -> atendida)
  # Map.fetch!(@transiciones, actual) devuelve la lista de estados a los que puede pasar desde el estado actual
  # el if verifica si el nuevo estado está en esa lista
  def cambiar_estado(%Necesidad{estado: actual} = n, nuevo) when nuevo in @estados do
    if nuevo in Map.fetch!(@transiciones, actual) do
      {:ok, %Necesidad{n | estado: nuevo}}
    else
      {:error, "transición no permitida: #{actual} -> #{nuevo}"}
    end
  end

  def cambiar_estado(_n, nuevo), do: {:error, "estado inválido: #{inspect(nuevo)}"}

  # Una necesidad atendida o cancelada no debe consumir más recursos
  def puede_recibir_recursos?(%Necesidad{estado: estado}),
    do: estado in [:pendiente, :asignada, :en_atencion]

  # La prioridad ordena la atención: crítica primero
  # Enum.sort_by ordena la lista de necesidades según el peso de su prioridad
  # &@peso_prioridad[&1.prioridad] busca en el mapa @peso_prioridad el número de la prioridad de cada necesidad
  # :desc ordena de mayor a menor peso (critica = 3 va primero, baja = 0 va al final)
  # Las que tienen la misma prioridad conservan su orden de llegada
  def ordenar_por_prioridad(necesidades) do
    Enum.sort_by(necesidades, &@peso_prioridad[&1.prioridad], :desc)
  end

  def filtrar_necesidades([], _zona, _tipo, _prioridad, _estado), do: []
  def filtrar_necesidades([n | resto], zona, tipo, prioridad, estado) do
    c_zona = zona == nil or n.zona == zona
    c_tipo = tipo == nil or n.tipo == tipo
    c_prio = prioridad == nil or n.prioridad == prioridad
    c_est = estado == nil or n.estado == estado

    if c_zona and c_tipo and c_prio and c_est do
      [n | filtrar_necesidades(resto, zona, tipo, prioridad, estado)]
    else
      filtrar_necesidades(resto, zona, tipo, prioridad, estado)
    end
  end

  def tipos, do: @tipos
  def prioridades, do: @prioridades
  def estados, do: @estados
end
