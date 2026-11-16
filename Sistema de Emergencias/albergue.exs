defmodule Albergue do

  defstruct [:codigo, :nombre, :zona, :capacidad_maxima, ocupacion_actual: 0, personas: [], recursos: [], necesidades: []]

def crear_albergue(codigo, nombre, zona, capacidad) do
    cond do
      not texto_valido?(codigo) ->
        {:error, "El código del albergue no puede estar vacío"}

      not texto_valido?(nombre) ->
        {:error, "El nombre del albergue no puede estar vacío"}

      not texto_valido?(zona) ->
        {:error, "La zona del albergue no puede estar vacía"}

      not (is_integer(capacidad) and capacidad > 0) ->
        {:error, "La capacidad debe ser un entero mayor que 0"}

      true ->
        {:ok,
         %Albergue{
           codigo: String.trim(codigo),
           nombre: String.trim(nombre),
           zona: String.trim(zona),
           capacidad_maxima: capacidad
         }}
    end
  end

defp texto_valido?(val), do: is_binary(val) and String.trim(val) != ""

  def cupos_disponibles(%Albergue{capacidad_maxima: maxima, ocupacion_actual: ocupacion}),
   do: maxima - ocupacion
  # Porcentaje de ocupación (sirve para el reporte de albergues más llenos)

  def porcentaje_ocupacion(%Albergue{capacidad_maxima: maxima, ocupacion_actual: ocupacion}),
    do: ocupacion / maxima * 100

#enum.member? verifica si el elemento esta en la lista
 def registrar_ingreso(%Albergue{} = albergue, documento) do
    cond do
      not texto_valido?(documento) ->
        {:error, "El documento de la persona no puede estar vacío"}

      Enum.member?(albergue.personas, String.trim(documento)) ->
        {:error, "La persona '#{String.trim(documento)}' ya está en el albergue"}

      cupos_disponibles(albergue) <= 0 ->
        {:error, "El albergue '#{albergue.codigo}' está lleno (capacidad máxima: #{albergue.capacidad_maxima})"}

      true ->
        doc_limpio = String.trim(documento)

        {:ok,
         %Albergue{
           albergue
           | personas: [doc_limpio | albergue.personas],
             ocupacion_actual: albergue.ocupacion_actual + 1
         }}
    end
  end

#list.delete elimina el primer elemento que coincida con el valor dado
# si no lo encuentra devuelve la lista original
def registrar_salida(%Albergue{} = albergue, documento) do
    if texto_valido?(documento) and Enum.member?(albergue.personas, String.trim(documento)) do
      doc_limpio = String.trim(documento)

      {:ok,
       %Albergue{
         albergue
         | personas: List.delete(albergue.personas, doc_limpio),
           ocupacion_actual: albergue.ocupacion_actual - 1
       }}
    else
      {:error, "La persona '#{documento}' no está registrada en el albergue"}
    end
  end

 def asociar_recurso(%Albergue{} = albergue, codigo_recurso) do
    cond do
      not texto_valido?(codigo_recurso) ->
        {:error, "El código del recurso no puede estar vacío"}

      codigo_recurso in albergue.recursos ->
        {:error, "El recurso '#{codigo_recurso}' ya está asociado a este albergue"}

      true ->
        {:ok, %Albergue{albergue | recursos: [codigo_recurso | albergue.recursos]}}
    end
  end

  def asociar_necesidad(%Albergue{} = albergue, id_necesidad) do
    cond do
      not texto_valido?(id_necesidad) ->
        {:error, "El ID de la necesidad no puede estar vacío"}

      id_necesidad in albergue.necesidades ->
        {:error, "La necesidad '#{id_necesidad}' ya está asociada a este albergue"}

      true ->
        {:ok, %Albergue{albergue | necesidades: [id_necesidad | albergue.necesidades]}}
    end
  end
   def reporte_mayor_ocupacion([]), do: []

  def reporte_mayor_ocupacion([albergue | resto]) do
    insertar_ordenado(albergue, reporte_mayor_ocupacion(resto))
  end

  defp insertar_ordenado(albergue, []), do: [albergue]
  defp insertar_ordenado(albergue, [cabeza | cola]) do
    if porcentaje_ocupacion(albergue) >= porcentaje_ocupacion(cabeza) do
      [albergue, cabeza | cola]
    else
      [cabeza | insertar_ordenado(albergue, cola)]
    end
  end
end
