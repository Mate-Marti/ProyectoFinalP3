defmodule Albergue do

  defstruct [:codigo, :nombre, :zona, :capacidad_maxima, ocupacion_actual: 0, personas: [], recursos: [], necesidades: []]

  def crear_albergue(codigo, nombre, zona, capacidad) when capacidad > 0 do
    %Albergue{
      codigo: codigo,
      nombre: nombre,
      zona: zona,
      capacidad_maxima: capacidad
    }
  end
end
