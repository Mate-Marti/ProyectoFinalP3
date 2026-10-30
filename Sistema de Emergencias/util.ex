defmodule Util do
  def mostrar_mensaje({:ok, mensaje}) do
    IO.puts(mensaje)
  end

  def mostrar_mensaje({:error, mensaje}) do
    IO.puts(mensaje)
  end

  def mostrar_mensaje(mensaje) do
    IO.puts(mensaje)
  end

  def mostrar_error(mensaje) do
    IO.puts(:standard_error, mensaje)
  end

  def mostrar_mensaje_java(mensaje) do
    System.cmd("java", ["-cp", ".", "Mensaje", mensaje])
  end

  def ingresar(mensaje, :texto) do
    mensaje
    |> IO.gets()
    |> String.trim()
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
        "Error, se espera que ingrese un número #{tipo_dato}\n"
        |> mostrar_error()

        mensaje
        |> ingresar(parser, tipo_dato)
    end
  end

  defp convertir_booleano(valor) do
    case valor |> String.downcase() do
     v when v in ["si", "sí", "s"] -> true
     v when v in ["no", "n"] -> false
    _ -> raise ArgumentError
    end
  end

  def formater(valor) do
    valor
    |> Kernel.*(1.0)
    |> :erlang.float_to_binary(valor, decimals: 2)
  end
end
