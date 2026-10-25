defmodule Recurso do

  defstruct [:codigo, :nombre, :categoria, :cantidad, :unidad, :ubicacion]

  def crear_recurso(codigo, nombre, categoria, cantidad, unidad, ubicacion) when cantidad >= 0 do
    %Recurso{
      codigo: codigo,
      nombre: nombre,
      categoria: categoria,
      cantidad: cantidad,
      unidad: unidad,
      ubicacion: ubicacion
    }
  end
end
