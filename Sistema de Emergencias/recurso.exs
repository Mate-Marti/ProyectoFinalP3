defmodule Recurso do
  @moduledoc "Recurso de inventario con historial de movimientos."

  defstruct [:codigo, :nombre, :categoria, :cantidad, :unidad, :ubicacion, historial: []]
def crear_recurso(codigo, nombre, categoria, cantidad, unidad, ubicacion) do
    cond do
      not texto_valido?(codigo) ->
        {:error, "El código del recurso no puede estar vacío"}

      not texto_valido?(nombre) ->
        {:error, "El nombre del recurso no puede estar vacío"}

      not texto_valido?(categoria) and not is_atom(categoria) ->
        {:error, "La categoría del recurso no puede estar vacía"}

      not texto_valido?(unidad) ->
        {:error, "La unidad de medida no puede estar vacía"}

      not texto_valido?(ubicacion) ->
        {:error, "La ubicación del recurso no puede estar vacía"}

      not (is_number(cantidad) and cantidad >= 0) ->
        {:error, "La cantidad no puede ser negativa"}

      true ->
        {:ok,
         %Recurso{
           codigo: String.trim(codigo),
           nombre: String.trim(nombre),
           categoria: categoria,
           cantidad: cantidad,
           unidad: String.trim(unidad),
           ubicacion: String.trim(ubicacion)
         }}
    end
  end

  defp texto_valido?(val), do: is_binary(val) and String.trim(val) != ""

  
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

   def transferir(%Recurso{} = origen, %Recurso{} = destino, cantidad) do
    if origen.ubicacion == destino.ubicacion do
      {:error, "La ubicación de destino no puede ser igual a la de origen (#{origen.ubicacion})"}
    else
      with {:ok, origen_act} <- salida(origen, cantidad),
           {:ok, destino_act} <- entrada(destino, cantidad) do
        {:ok, origen_act, destino_act}
      end
    end
  end

  def consultar_disponibilidad([], _categoria, _zona), do: []
  def consultar_disponibilidad([r | resto], categoria, zona) do
    cumple_cat = categoria == nil or r.categoria == categoria
    cumple_zona = zona == nil or r.ubicacion == zona

    if cumple_cat and cumple_zona do
      [r | consultar_disponibilidad(resto, categoria, zona)]
    else
      consultar_disponibilidad(resto, categoria, zona)
    end
  end

  def recursos_criticos([], _umbral), do: []
  def recursos_criticos([r | resto], umbral) when r.cantidad <= umbral do
    [r | recursos_criticos(resto, umbral)]
  end
  def recursos_criticos([_r | resto], umbral), do: recursos_criticos(resto, umbral)

#datatime.utc_now() devuelve la fecha y hora actual en formato UTC
  defp mover(r, tipo, cantidad, nueva_cantidad) do
    movimiento = {tipo, cantidad, DateTime.utc_now()}
    %Recurso{r | cantidad: nueva_cantidad, historial: [movimiento | r.historial]}
  end
end
