defmodule PersonaAfectada do
  @moduledoc "Persona afectada, con historial de cambios de estado."

  defstruct [:id, :documento, :nombre, :edad, :zona, estado: :sin_informacion, historial: []]

  @estados [:sin_informacion, :reportada, :localizada, :trasladada, :en_albergue, :reunificada]

  def crear_afectada(id, documento, nombre, edad, zona, estado \\ :sin_informacion) do
    cond do
      not texto_valido?(id) ->
        {:error, "El ID no puede estar vacío"}

      not texto_valido?(documento) ->
        {:error, "El documento no puede estar vacío"}

      not texto_valido?(nombre) ->
        {:error, "El nombre no puede estar vacío"}

      not texto_valido?(zona) ->
        {:error, "La zona no puede estar vacía"}

      estado not in @estados ->
        {:error, "Estado inválido. Opciones: #{inspect(@estados)}"}

      not (is_integer(edad) and edad >= 0) ->
        {:error, "La edad debe ser un entero >= 0"}

      true ->
        {:ok,
         %PersonaAfectada{
           id: String.trim(id),
           documento: String.trim(documento),
           nombre: String.trim(nombre),
           edad: edad,
           zona: String.trim(zona),
           estado: estado
         }}
    end
  end

  defp texto_valido?(val), do: is_binary(val) and String.trim(val) != ""

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

  def buscar_personas([], _criterio), do: []
 def buscar_personas([p | resto], criterio) do
    criterio_str = String.downcase(String.trim(to_string(criterio)))

    if String.downcase(p.documento) == criterio_str or
         String.contains?(String.downcase(p.nombre), criterio_str) or
         String.downcase(p.zona) == criterio_str or
         Atom.to_string(p.estado) == criterio_str do
      [p | buscar_personas(resto, criterio)]
    else
      buscar_personas(resto, criterio)
    end
  end
end