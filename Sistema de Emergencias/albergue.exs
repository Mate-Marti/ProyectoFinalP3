defmodule Albergue do

  defstruct [:codigo, :nombre, :zona, :capacidad_maxima, ocupacion_actual: 0, personas: [], recursos: [], necesidades: []]

#is_integer verifica si es un entero y > 0 verifica que sea mayor a 0
   def crear_albergue(codigo, nombre, zona, capacidad)
      when is_integer(capacidad) and capacidad > 0 do
    {:ok, %Albergue{codigo: codigo, nombre: nombre, zona: zona, capacidad_maxima: capacidad}}
  end

  def crear_albergue(_codigo, _nombre, _zona, _capacidad),
    do: {:error, "la capacidad debe ser un entero mayor que 0"}

  def cupos_disponibles(%Albergue{capacidad_maxima: maxima, ocupacion_actual: ocupacion}), do: maxima - ocupacion

  # Porcentaje de ocupación (sirve para el reporte de albergues más llenos)

  def porcentaje_ocupacion(%Albergue{capacidad_maxima: maxima, ocupacion_actual: ocupacion}),
    do: ocupacion / maxima * 100

#enum.member? verifica si el elemento esta en la lista
  def registrar_ingreso(%Albergue{} = albergue, documento) do
  cond do
    Enum.member?(albergue.personas, documento) ->
      {:error, "la persona #{documento} ya está en el albergue"}

    cupos_disponibles(albergue) <= 0 ->
      {:error, "el albergue #{albergue.codigo} está lleno"}

    true ->
      {:ok,
       %Albergue{albergue |
         personas: [documento | albergue.personas],
         ocupacion_actual: albergue.ocupacion_actual + 1}}
  end
end

#list.delete elimina el primer elemento que coincida con el valor dado
# si no lo encuentra devuelve la lista original
  def registrar_salida(%Albergue{} = albergue, documento) do
    if Enum.member?(albergue.personas, documento) do
      {:ok,
       %Albergue{
         albergue
         | personas: List.delete(albergue.personas, documento),
           ocupacion_actual: albergue.ocupacion_actual - 1
       }}
    else
      {:error, "la persona #{documento} no está en el albergue"}
    end
  end

  def asociar_recurso(%Albergue{} = albergue, codigo_recurso) do
    {:ok, %Albergue{albergue | recursos: [codigo_recurso | albergue.recursos]}}
  end

  def asociar_necesidad(%Albergue{} = albergue, id_necesidad) do
    {:ok, %Albergue{albergue | necesidades: [id_necesidad | albergue.necesidades]}}
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
