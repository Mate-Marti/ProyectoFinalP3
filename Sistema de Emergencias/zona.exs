defmodule Zona do
  @moduledoc """
  Zona afectada. Estructura: zona -> sectores -> puntos de atención.
  Un sector es un mapa: %{nombre: .., personas: n, puntos_atencion: [..], subsectores: [..]}
  """

  defstruct [
    :codigo,
    :nombre,
    :nivel_afectacion,
    personas_afectadas: 0,
    sectores: [],
    puntos_atencion: []
  ]

  @niveles [:critico, :alto, :medio, :bajo]

  def crear_zona(codigo, nombre, nivel, personas \\ 0) do
    cond do
      nivel not in @niveles ->
        {:error, "nivel inválido. Opciones: #{inspect(@niveles)}"}

      not (is_integer(personas) and personas >= 0) ->
        {:error, "personas debe ser un entero >= 0"}

      true ->
        {:ok,
         %Zona{
           codigo: codigo,
           nombre: nombre,
           nivel_afectacion: nivel,
           personas_afectadas: personas
         }}
    end
  end

  def crear_sector(nombre, personas, puntos_atencion \\ [], subsectores \\ [])
      when is_integer(personas) and personas >= 0 do
    %{
      nombre: nombre,
      personas: personas,
      puntos_atencion: puntos_atencion,
      subsectores: subsectores
    }
  end
  #zona.sectores ++ [sector] agrega el sector al final de la lista de sectores

  def agregar_sector(%Zona{} = zona, sector),
    do: %Zona{zona | sectores: zona.sectores ++ [sector]}

  # RECURSIVA: personas de todos los sectores y subsectores
  def total_personas([]), do: 0

  def total_personas([sector | resto]) do
    sector.personas + total_personas(sector.subsectores) + total_personas(resto)
  end

  # RECURSIVA: puntos de atención de todos los sectores y subsectores
  def contar_puntos_atencion([]), do: 0

  def contar_puntos_atencion([sector | resto]) do
    length(sector.puntos_atencion) + contar_puntos_atencion(sector.subsectores) +
      contar_puntos_atencion(resto)
  end

  def niveles, do: @niveles
end
