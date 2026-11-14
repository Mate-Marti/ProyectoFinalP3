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
    if tipo in @tipos do
      {:ok,
       %ReporteMascota{
         id: id,
         tipo_reporte: tipo,
         especie: especie,
         nombre: nombre,
         caracteristicas: carac,
         color: color,
         tamano: tamano,
         zona: zona,
         contacto: contacto
       }}
    else
      {:error, "tipo de reporte inválido. Opciones: #{inspect(@tipos)}"}
    end
  end

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
end
