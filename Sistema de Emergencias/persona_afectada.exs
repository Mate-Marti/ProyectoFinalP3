defmodule PersonaAfectada do
  @moduledoc "Persona afectada, con historial de cambios de estado."

  defstruct [:id, :documento, :nombre, :edad, :zona, estado: :sin_informacion, historial: []]

  @estados [:sin_informacion, :reportada, :localizada, :trasladada, :en_albergue, :reunificada]

  def crear_afectada(id, documento, nombre, edad, zona, estado \\ :sin_informacion) do
    cond do
      estado not in @estados ->
        {:error, "estado inválido. Opciones: #{inspect(@estados)}"}

      not (is_integer(edad) and edad >= 0) ->
        {:error, "la edad debe ser un entero >= 0"}

      true ->
        {:ok,
         %PersonaAfectada{
           id: id,
           documento: documento,
           nombre: nombre,
           edad: edad,
           zona: zona,
           estado: estado
         }}
    end
  end

  # Guarda en el historial cada cambio: {estado_anterior, estado_nuevo, fecha}
  def cambiar_estado(%PersonaAfectada{estado: igual}, igual),
    do: {:error, "la persona ya está en estado #{igual}"}
#el datatime.utc_now() devuelve la fecha y hora actual en formato UTC
  def cambiar_estado(%PersonaAfectada{} = p, nuevo) when nuevo in @estados do
    registro = {p.estado, nuevo, DateTime.utc_now()}
    {:ok, %PersonaAfectada{p | estado: nuevo, historial: [registro | p.historial]}}
  end

  def cambiar_estado(_p, nuevo), do: {:error, "estado inválido: #{inspect(nuevo)}"}

  def estados, do: @estados
end
