defmodule Recurso do
  @moduledoc "Recurso de inventario con historial de movimientos."

  defstruct [:codigo, :nombre, :categoria, :cantidad, :unidad, :ubicacion, historial: []]

  def crear_recurso(codigo, nombre, categoria, cantidad, unidad, ubicacion)
      when is_number(cantidad) and cantidad >= 0 do
    {:ok,
     %Recurso{
       codigo: codigo,
       nombre: nombre,
       categoria: categoria,
       cantidad: cantidad,
       unidad: unidad,
       ubicacion: ubicacion
     }}
  end

  def crear_recurso(_c, _n, _cat, _cantidad, _u, _ub),
    do: {:error, "la cantidad no puede ser negativa"}

  # Entrada de inventario
  def entrada(%Recurso{} = r, cantidad) when is_number(cantidad) and cantidad > 0 do
    {:ok, mover(r, :entrada, cantidad, r.cantidad + cantidad)}
  end

  def entrada(_r, _cantidad), do: {:error, "la cantidad debe ser mayor que 0"}

  # Salida de inventario: nunca deja el stock en negativo
  def salida(%Recurso{} = r, cantidad) when is_number(cantidad) and cantidad > 0 do
    if cantidad <= r.cantidad do
      {:ok, mover(r, :salida, cantidad, r.cantidad - cantidad)}
    else
      {:error, "inventario insuficiente: hay #{r.cantidad} #{r.unidad} y se piden #{cantidad}"}
    end
  end

  def salida(_r, _cantidad), do: {:error, "la cantidad debe ser mayor que 0"}
#datatime.utc_now() devuelve la fecha y hora actual en formato UTC
  defp mover(r, tipo, cantidad, nueva_cantidad) do
    movimiento = {tipo, cantidad, DateTime.utc_now()}
    %Recurso{r | cantidad: nueva_cantidad, historial: [movimiento | r.historial]}
  end
end
