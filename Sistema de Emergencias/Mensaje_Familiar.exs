defmodule MensajeFamiliar do
  @moduledoc "Mensaje dirigido a una persona o familia."

  defstruct [:id, :fecha, :remitente, :destinatario, :contenido, estado: :pendiente]

  @estados [:pendiente, :entregado]
#datatime.utc_now() devuelve la fecha y hora actual en formato UTC del sistema
  def crear_mensaje(id, remitente, destinatario, contenido) do
    cond do
      not texto_valido?(id) ->
        {:error, "El ID del mensaje no puede estar vacío"}

      not texto_valido?(remitente) ->
        {:error, "El remitente no puede estar vacío"}

      not texto_valido?(destinatario) ->
        {:error, "El destinatario no puede estar vacío"}

      not texto_valido?(contenido) ->
        {:error, "El contenido del mensaje no puede estar vacío"}

      true ->
        {:ok,
         %MensajeFamiliar{
           id: String.trim(id),
           fecha: DateTime.utc_now(),
           remitente: String.trim(remitente),
           destinatario: String.trim(destinatario),
           contenido: String.trim(contenido)
         }}
    end
  end

  defp texto_valido?(val), do: is_binary(val) and String.trim(val) != ""

  
  def marcar_entregado(%MensajeFamiliar{estado: :entregado}),
    do: {:error, "el mensaje ya estaba entregado"}

  def marcar_entregado(%MensajeFamiliar{} = mensaje) do
    {:ok, %MensajeFamiliar{mensaje | estado: :entregado}}
  end

  def marcar_pendiente(%MensajeFamiliar{} = mensaje) do
    {:ok, %MensajeFamiliar{mensaje | estado: :pendiente}}
  end

  def estados, do: @estados

  def listar_mensajes([], _destinatario), do: []
  def listar_mensajes([m | resto], destinatario) when m.destinatario == destinatario do
    [m | listar_mensajes(resto, destinatario)]
  end
  def listar_mensajes([_m | resto], destinatario), do: listar_mensajes(resto, destinatario)
  
end
