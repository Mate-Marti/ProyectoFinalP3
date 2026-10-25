defmodule Necesidad do

  defstruct [:id, :tipo, :descripcion, :cantidad, :zona, :prioridad, :responsable, estado: :pendiente]

  def crear_necesidad(id, tipo, desc, cant, zona, prio, resp) when cant > 0 do
    %Necesidad{
      id: id,
      tipo: tipo,
      descripcion: desc,
      cantidad: cant,
      zona: zona,
      prioridad: prio,
      responsable: resp
    }
  end
end
