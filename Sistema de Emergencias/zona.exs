defmodule Zona do

  defstruct [:codigo, :nombre, :nivel_afectacion, personas_afectadas: 0, sectores: [], albergues: [], necesidades: [], recursos: [], reportes: []]
@niveles [:critico, :alto, :medio, :bajo]
 
  def crear_zona(codigo, nombre, nivel, personas \\ 0)

  def crear_zona(codigo, nombre, nivel, personas) do
    with :ok <- validar_texto(codigo, "código de zona"),
         :ok <- validar_texto(nombre, "nombre de zona"),
         :ok <- validar_nivel(nivel),
         :ok <- validar_entero_no_negativo(personas, "personas afectadas") do
      {:ok,
       %Zona{
         codigo: String.trim(codigo),
         nombre: String.trim(nombre),
         nivel_afectacion: nivel,
         personas_afectadas: personas
       }}
    end
  end

#retorna {:ok, zona} o {:error, motivo} validando duplicados y negativos
  def agregar_sector(%Zona{} = zona, codigo_sector, nombre_sector, personas \\ 0) do
    with :ok <- validar_texto(codigo_sector, "código de sector"),
         :ok <- validar_texto(nombre_sector, "nombre de sector"),
         :ok <- validar_entero_no_negativo(personas, "personas afectadas del sector"),
         false <- existe_sector?(zona.sectores, String.trim(codigo_sector)) do
      nuevo_sector = %{
        codigo: String.trim(codigo_sector),
        nombre: String.trim(nombre_sector),
        personas_afectadas: personas,
        puntos_atencion: []
      }

      {:ok, %{zona | sectores: [nuevo_sector | zona.sectores]}}
    else
      true -> {:error, "El sector '#{codigo_sector}' ya existe en la zona '#{zona.codigo}'"}
      error -> error
    end
  end

   # CORREGIDO: Si el sector no existe o el punto ya existe/está vacío, devuelve {:error, motivo}
  def agregar_punto_atencion(%Zona{} = zona, codigo_sector, punto_atencion) do
    with :ok <- validar_texto(codigo_sector, "código de sector"),
         :ok <- validar_texto(punto_atencion, "punto de atención"),
         {:ok, nuevos_sectores} <-
           insertar_punto_rec(zona.sectores, String.trim(codigo_sector), String.trim(punto_atencion)) do
      {:ok, %{zona | sectores: nuevos_sectores}}
    end
  end

  #función para cuando no se encuentra el sector, retorna la lista de sectores sin cambios
  defp insertar_punto_rec([], codigo_sector, _punto), 
  do: {:error, "El sector '#{codigo_sector}' no existe en la zona"}

  #función para cuando encuentra el sector, inserta el punto de atención y retorna la lista de sectores actualizada
  defp insertar_punto_rec([sector | resto], codigo_sector, punto)
   when sector.codigo == codigo_sector do
    if punto in sector.puntos_atencion do
      {:error, "El punto de atención '#{punto}' ya está registrado en el sector '#{codigo_sector}'"}
    else
      sector_actualizado = %{sector | puntos_atencion: [punto | sector.puntos_atencion]}
      {:ok, [sector_actualizado | resto]}
    end
  end

  defp insertar_punto_rec([sector | resto], codigo_sector, punto) do
    case insertar_punto_rec(resto, codigo_sector, punto) do
      {:ok, resto_actualizado} -> {:ok, [sector | resto_actualizado]}
      error -> error
    end
  end

    # Asociar albergues, necesidades, recursos o reportes sin duplicar IDs
  def asociar(%Zona{} = zona, tipo, id_elemento)
      when tipo in [:albergues, :necesidades, :recursos, :reportes] do
    lista_actual = Map.get(zona, tipo)

    if id_elemento in lista_actual do
      zona
    else
      Map.put(zona, tipo, [id_elemento | lista_actual])
    end
  end

  #Consultar el estado general de una zona
  def estado_general(%Zona{} = zona) do
    %{
      codigo: zona.codigo,
      nombre: zona.nombre,
      nivel_afectacion: zona.nivel_afectacion,
      personas_afectadas: zona.personas_afectadas,
      cantidad_sectores: length(zona.sectores),
      albergues: zona.albergues,
      necesidades: zona.necesidades,
      recursos: zona.recursos,
      reportes: zona.reportes
    }
  end

  #Estadísticas acumuladas recorriendo recursivamente zona -> sectores -> puntos de atención
  def estadisticas_acumuladas(%Zona{} = zona) do
    {personas_sectores, total_sectores, total_puntos} =
      recorrer_sectores_rec(zona.sectores, 0, 0, 0)

    %{
      codigo: zona.codigo,
      nombre: zona.nombre,
      nivel_afectacion: zona.nivel_afectacion,
      total_personas_afectadas: zona.personas_afectadas + personas_sectores,
      total_sectores: total_sectores,
      total_puntos_atencion: total_puntos,
      total_albergues: length(zona.albergues),
      total_necesidades: length(zona.necesidades),
      total_recursos: length(zona.recursos),
      total_reportes: length(zona.reportes)
    }
  end

  #funciones recursivas para recorrer los sectores y contar los puntos de atención
  defp recorrer_sectores_rec([], acc_personas, acc_sectores, acc_puntos),
   do: {acc_personas, acc_sectores, acc_puntos}

  #funcion para cuando encuentra un sector, suma las personas afectadas y cuenta los puntos de atención del sector, luego sigue recorriendo el resto de los sectores
  defp recorrer_sectores_rec([sector | resto], acc_personas, acc_sectores, acc_puntos) do
    puntos_del_sector = contar_puntos_rec(sector.puntos_atencion, 0)

    recorrer_sectores_rec(
      resto,
      acc_personas + sector.personas_afectadas,
      acc_sectores + 1,
      acc_puntos + puntos_del_sector
    )
  end

  #funciones para contar los puntos de atención de un sector
  defp contar_puntos_rec([], acc), do: acc
  defp contar_puntos_rec([_punto | resto], acc), do: contar_puntos_rec(resto, acc + 1)

    # Helpers de validación
  defp existe_sector?([], _cod), do: false
  defp existe_sector?([s | _], cod) when s.codigo == cod, do: true
  defp existe_sector?([_ | t], cod), do: existe_sector?(t, cod)

  defp validar_texto(val, campo) when is_binary(val) do
    if String.trim(val) == "", do: {:error, "El campo '#{campo}' no puede estar vacío"}, else: :ok
  end

  defp validar_texto(_, campo), do: {:error, "El campo '#{campo}' debe ser texto"}

  defp validar_nivel(nivel) when nivel in @niveles, do: :ok
  defp validar_nivel(nivel), do: {:error, "Nivel inválido: #{inspect(nivel)}. Válidos: #{inspect(@niveles)}"}

  defp validar_entero_no_negativo(n, _campo) when is_integer(n) and n >= 0, do: :ok
  defp validar_entero_no_negativo(_, campo), do: {:error, "El campo '#{campo}' debe ser un entero >= 0"}
end
