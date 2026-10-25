defmodule Zona do

  defstruct [:codigo, :nombre, :nivel_afectacion, personas_afectadas: 0, sectores: [], puntos_atencion: []]

  def crear_zona(codigo, nombre, nivel, personas \\ 0) when nivel in [:critico, :alto, :medio, :bajo] do
    %Zona{
      codigo: codigo,
      nombre: nombre,
      nivel_afectacion: nivel,
      personas_afectadas: personas
    }
  end
end
