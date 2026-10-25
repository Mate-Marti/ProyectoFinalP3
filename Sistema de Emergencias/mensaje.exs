defmodule MensajeFamiliar do

  defstruct [:id, :fecha, :remitente, :destinatario, :contenido, estado: :pendiente]

  def crear_mensaje(id, remitente, destinatario, contenido) do
    %MensajeFamiliar{
      id: id,
      fecha: DateTime.utc_now(),
      remitente: remitente,
      destinatario: destinatario,
      contenido: contenido
    }
  end
end
