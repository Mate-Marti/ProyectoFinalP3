defmodule ReporteMascota do

  defstruct [:id, :tipo_reporte, :especie, :nombre, :caracteristicas, :color, :tamano, :zona, :contacto, estado: :activa]

  def crear_reporte(id, tipo, especie, nombre, carac, color, tamano, zona, contacto) when tipo in [:perdida, :encontrada] do
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
    }
  end
end
