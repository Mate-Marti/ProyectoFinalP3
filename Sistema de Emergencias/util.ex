defmodule Util do
  def mostrar_mensaje({:ok, mensaje}), do: IO.puts(mensaje)
  def mostrar_mensaje({:error, mensaje}), do: mostrar_error(mensaje)
  def mostrar_mensaje(mensaje), do: IO.puts(mensaje)

  def mostrar_error(mensaje) do
    IO.puts(:standard_error, "Error: #{mensaje}")
  end

  def ingresar(mensaje, :texto) do
    case IO.gets(mensaje) do
      :eof -> ""
      {:error, _} -> ""
      texto -> String.trim(texto)
    end
  end

  # NUEVO: Evita que el usuario deje campos obligatorios en blanco al dar Enter
  def ingresar(mensaje, :texto_no_vacio) do
    valor = ingresar(mensaje, :texto)

    if valor == "" do
      mostrar_error("El campo no puede estar vacío. Intente nuevamente.")
      ingresar(mensaje, :texto_no_vacio)
    else
      valor
    end
  end

  def ingresar(mensaje, :entero) do
    ingresar(mensaje, &String.to_integer/1, :entero)
  end

  def ingresar(mensaje, :real) do
    ingresar(mensaje, &String.to_float/1, :real)
  end

  def ingresar(mensaje, :booleano) do
    ingresar(mensaje, &convertir_booleano/1, :booleano)
  end

  def ingresar(mensaje, parser, tipo_dato) do
    try do
      mensaje
      |> ingresar(:texto)
      |> parser.()
    rescue
      ArgumentError ->
        mostrar_error("Se espera que ingrese un valor válido de tipo #{tipo_dato}.\n")
        ingresar(mensaje, parser, tipo_dato)
    end
  end

  defp convertir_booleano(valor) do
    case String.downcase(valor) do
      v when v in ["si", "sí", "s"] -> true
      v when v in ["no", "n"] -> false
      _ -> raise ArgumentError
    end
  end

  def formater(valor), do: :erlang.float_to_binary(valor * 1.0, decimals: 2)
end