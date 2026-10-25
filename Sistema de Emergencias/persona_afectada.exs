defmodule PersonaAfectada do

  defstruct [:id, :documento, :nombre, :edad, :zona, estado: :sin_informacion]

  def crear_afectada(id, documento, nombre, edad, zona, estado \\ :sin_informacion) do
    %PersonaAfectada{
      id: id,
      documento: documento,
      nombre: nombre,
      edad: edad,
      zona: zona,
      estado: estado,
    }
  end
end
