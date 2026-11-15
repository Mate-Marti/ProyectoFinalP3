defmodule MensajeFamiliar do
  @moduledoc "Mensaje dirigido a una persona o familia."

  defstruct [:id, :fecha, :remitente, :destinatario, :contenido, estado: :pendiente]

  @estados [:pendiente, :entregado]
#datatime.utc_now() devuelve la fecha y hora actual en formato UTC del sistema
  def crear_mensaje(id, remitente, destinatario, contenido) do
    if String.trim(to_string(contenido)) == "" do
      {:error, "el mensaje no puede estar vacío"}
    else
      {:ok,
       %MensajeFamiliar{
         id: id,
         fecha: DateTime.utc_now(),
         remitente: remitente,
         destinatario: destinatario,
         contenido: contenido
       }}
    end
  end

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
