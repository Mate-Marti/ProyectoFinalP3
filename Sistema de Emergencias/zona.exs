defmodule Zona do

  defstruct [:codigo, :nombre, :nivel_afectacion, personas_afectadas: 0, sectores: [], albergues: [], necesidades: [], recursos: [], reportes: []]

  def crear_zona(codigo, nombre, nivel, personas \\ 0)

  def crear_zona(codigo, nombre, nivel, personas)
      when nivel in [:critico, :alto, :medio, :bajo] and is_integer(personas) and personas >= 0 do
    {:ok,
      %Zona{
      codigo: codigo,
      nombre: nombre,
      nivel_afectacion: nivel,
      personas_afectadas: personas
    }}
  end

  def crear_zona(_codigo, _nombre, _nivel, _personas),
    do: {:error, "nivel de afectación o cantidad de personas invalidos"}

  #registrar un sector en la zona
  def agregar_sector(%Zona{} = zona, codigo_sector, nombre_sector, personas \\ 0) do
    nuevo_sector = %{
      codigo: codigo_sector,
      nombre: nombre_sector,
      personas_afectadas: personas,
      puntos_atencion: [],
    }

    %{zona | sectores: [nuevo_sector | zona.sectores]}
  end


  #Registrar un punto de atención dentro de un sector (estructura: zona -> sectores -> puntos_atencion)
  def agregar_punto_atencion(%Zona{} = zona, codigo_sector, punto_atencion) do
    nuevos_sectores = insertar_punto_rec(zona.sectores, codigo_sector, punto_atencion)
    %{zona | sectores: nuevos_sectores}
  end

  #función para cuando no se encuentra el sector, retorna la lista de sectores sin cambios
  defp insertar_punto_rec([], _codigo_sector, _punto), do: []

  #función para cuando encuentra el sector, inserta el punto de atención y retorna la lista de sectores actualizada
  defp insertar_punto_rec([sector | resto], codigo_sector, punto) when sector.codigo == codigo_sector do
    sector_actualizado = %{sector | puntos_atencion: [punto | sector.puntos_atencion]}
    [sector_actualizado | resto]
  end

  #funcion para cuando no encuentra el sector, sigue buscando en el resto de la lista de sectores
  defp insertar_punto_rec([sector | resto], codigo_sector, punto) do
    [sector | insertar_punto_rec(resto, codigo_sector, punto)]
  end

  #Asociar albergues, necesidades, recursos o reportes a la zona
  def asociar(%Zona{} = zona, tipo, id_elemento)
      when tipo in [:albergues, :necesidades, :recursos, :reportes] do
    lista_actual = Map.get(zona, tipo)
    Map.put(zona, tipo, [id_elemento | lista_actual])
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
  defp recorrer_sectores_rec([], acc_personas, acc_sectores, acc_puntos) do
    {acc_personas, acc_sectores, acc_puntos}
  end

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
end
