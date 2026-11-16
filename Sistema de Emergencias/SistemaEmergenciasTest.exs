ExUnit.start()

Code.require_file("util.ex", __DIR__)
Code.require_file("usuario.exs", __DIR__)
Code.require_file("zona.exs", __DIR__)
Code.require_file("recurso.exs", __DIR__)
Code.require_file("necesidad.exs", __DIR__)
Code.require_file("albergue.exs", __DIR__)
Code.require_file("persona_afectada.exs", __DIR__)
Code.require_file("Mensaje_Familiar.exs", __DIR__)
Code.require_file("reporte_mascota.exs", __DIR__)
Code.require_file("persistencia.exs", __DIR__)
Code.require_file("gestores/gestor_persistencia.exs", __DIR__)
Code.require_file("gestores/gestor_usuarios.exs", __DIR__)
Code.require_file("gestores/gestor_zonas.exs", __DIR__)
Code.require_file("gestores/gestor_recursos.exs", __DIR__)
Code.require_file("gestores/gestor_necesidades.exs", __DIR__)
Code.require_file("gestores/gestor_albergues.exs", __DIR__)
Code.require_file("gestores/gestor_familiares.exs", __DIR__)
Code.require_file("gestores/gestor_mascotas.exs", __DIR__)
Code.require_file("supervisor_emergencia.exs", __DIR__)

defmodule SistemaEmergenciasTest do
  use ExUnit.Case

  setup do
    ruta_datos = Path.join("resources", "emergencia.txt")
    File.mkdir_p!("resources")
    File.write!(ruta_datos, "")

    if pid = Process.whereis(SupervisorEmergencia) do
      Supervisor.stop(pid, :normal)
    end

    {:ok, _sup_pid} = SupervisorEmergencia.start_link()
    :ok
  end

  # ============================================================================
  # 1. PRUEBAS DE USUARIOS Y CONTROL DE ROLES
  # ============================================================================
  test "registro, autenticación, contraseña errónea y restricción por rol" do
    assert {:ok, u1} = GestorUsuarios.conectar("laura", "1234", "Laura Gómez", :coordinador, "centro")
    assert u1.conectado == true

    assert {:error, _} = GestorUsuarios.conectar("laura", "clave_mala", "Laura Gómez", :coordinador, "centro")
    assert {:error, _} = GestorUsuarios.conectar("", "1234", "Sin Nombre", :ciudadano, "centro")
    assert {:error, _} = GestorUsuarios.conectar("pedro", "1234", "Pedro", :superhero, "centro")

    assert {:ok, _} = GestorUsuarios.conectar("carlos", "abcd", "Carlos Ruiz", :ciudadano, "centro")
    assert {:error, msg_permiso} = GestorZonas.registrar_zona(Node.self(), "carlos", "Z01", "Centro", :critico, 100)
    assert msg_permiso =~ "permisos"

    assert {:ok, _} = GestorUsuarios.desconectar("carlos")
    assert {:error, _} = GestorUsuarios.desconectar("carlos")
  end

  # ============================================================================
  # 2. PRUEBAS DE ZONAS, SECTORES, PUNTOS DE ATENCIÓN Y RECURSIVIDAD
  # ============================================================================
  test "gestión jerárquica zona -> sectores -> puntos y validación de errores" do
    {:ok, _} = GestorUsuarios.conectar("laura", "1234", "Laura", :coordinador, "Z01")

    assert {:ok, _} = GestorZonas.registrar_zona(Node.self(), "laura", "Z01", "Zona Centro", :critico, 200)

    assert {:error, _} = GestorZonas.registrar_zona(Node.self(), "laura", "Z01", "Otra", :alto, 50)
    assert {:error, _} = GestorZonas.registrar_zona(Node.self(), "laura", "Z02", "Norte", :apocalipsis, 50)
    assert {:error, _} = GestorZonas.registrar_zona(Node.self(), "laura", "Z02", "Norte", :alto, -10)

    assert {:ok, _} = GestorZonas.agregar_sector(Node.self(), "laura", "Z01", "S01", "Sector Parque", 80)
    assert {:ok, _} = GestorZonas.agregar_punto_atencion("laura", "Z01", "S01", "Carpa Cruz Roja")
    assert {:ok, _} = GestorZonas.agregar_punto_atencion("laura", "Z01", "S01", "Hospital Móvil")

    assert {:error, _} = GestorZonas.agregar_punto_atencion("laura", "Z01", "S99", "Punto Fantasma")

    assert {:ok, stats} = GestorZonas.estadisticas_zona("Z01")
    assert stats.total_personas_afectadas == 280
    assert stats.total_sectores == 1
    assert stats.total_puntos_atencion == 2
  end

  # ============================================================================
  # 3. PRUEBAS DE NECESIDADES, PRIORIDAD Y TRANSICIONES DE ESTADO
  # ============================================================================
  test "ordenamiento por prioridad y bloqueo de doble cierre en necesidades" do
    {:ok, _} = GestorUsuarios.conectar("laura", "1234", "Laura", :coordinador, "Z01")
    {:ok, _} = GestorZonas.registrar_zona(Node.self(), "laura", "Z01", "Zona Centro", :critico, 100)

    assert {:error, _} = GestorNecesidades.registrar_necesidad("laura", "N00", :agua, "Agua", 10, "Z_NO_EXISTE", :alta)
    assert {:error, _} = GestorNecesidades.registrar_necesidad("laura", "N00", :agua, "Agua", 0, "Z01", :alta)

    assert {:ok, _} = GestorNecesidades.registrar_necesidad("laura", "N01", :alimentos, "Mercados", 20, "Z01", :baja)
    assert {:ok, _} = GestorNecesidades.registrar_necesidad("laura", "N02", :agua, "Agua potable", 30, "Z01", :critica)
    assert {:ok, _} = GestorNecesidades.registrar_necesidad("laura", "N03", :medicamentos, "Insulina", 5, "Z01", :alta)

    {:ok, ordenadas} = GestorNecesidades.listar_necesidades()
    assert Enum.map(ordenadas, & &1.id) == ["N02", "N03", "N01"]

    assert {:error, _} = GestorNecesidades.cambiar_estado("laura", "N01", :atendida)

    assert {:ok, _} = GestorNecesidades.cambiar_estado("laura", "N01", :cancelada)
    assert {:error, _} = GestorNecesidades.cambiar_estado("laura", "N01", :atendida)
  end

  # ============================================================================
  # 4. PRUEBA OBLIGATORIA DE CONCURRENCIA EN RECURSOS
  # ============================================================================
  test "conflicto concurrente: dos usuarios intentan reservar 30 y 25 litros cuando solo hay 50" do
    {:ok, _} = GestorUsuarios.conectar("laura", "1234", "Laura", :coordinador, "Z01")
    {:ok, _} = GestorUsuarios.conectar("andres", "5678", "Andrés", :coordinador, "Z01")
    {:ok, _} = GestorZonas.registrar_zona(Node.self(), "laura", "Z01", "Zona Centro", :critico, 300)

    assert {:ok, _} = GestorRecursos.registrar_recurso("laura", "R001", "Agua Embotellada", :agua, 50, "litros", "Z01")

    assert {:ok, _} = GestorNecesidades.registrar_necesidad("laura", "N001", :agua, "Punto 1", 30, "Z01", :critica)
    assert {:ok, _} = GestorNecesidades.registrar_necesidad("andres", "N002", :agua, "Punto 2", 25, "Z01", :critica)

    tarea1 = Task.async(fn -> GestorNecesidades.asignar_recurso("laura", "N001", "R001", 30) end)
    tarea2 = Task.async(fn -> GestorNecesidades.asignar_recurso("andres", "N002", "R001", 25) end)

    resultados = [Task.await(tarea1), Task.await(tarea2)]

    exitos = Enum.filter(resultados, &match?({:ok, _}, &1))
    fallos = Enum.filter(resultados, &match?({:error, _}, &1))

    assert length(exitos) == 1
    assert length(fallos) == 1

    {:ok, [recurso_final]} = GestorRecursos.listar_recursos()
    assert recurso_final.cantidad in [20, 25]
    assert recurso_final.cantidad >= 0
  end

  # ============================================================================
  # 5. PRUEBAS DE ALBERGUES, CAPACIDAD MÁXIMA Y CONCURRENCIA
  # ============================================================================
  test "albergues impiden superar capacidad máxima y duplicar ingresos" do
    {:ok, _} = GestorUsuarios.conectar("laura", "1234", "Laura", :coordinador, "Z01")
    {:ok, _} = GestorZonas.registrar_zona(Node.self(), "laura", "Z01", "Zona Centro", :alto, 100)

    assert {:ok, _} = GestorAlbergues.registrar_albergue("laura", "A01", "Albergue Norte", "Z01", 2)

    assert {:ok, _} = GestorAlbergues.ingreso_albergue("laura", "A01", "1001")
    assert {:error, _} = GestorAlbergues.ingreso_albergue("laura", "A01", "1001")
    assert {:ok, _} = GestorAlbergues.ingreso_albergue("laura", "A01", "1002")

    assert {:error, msg_lleno} = GestorAlbergues.ingreso_albergue("laura", "A01", "1003")
    assert msg_lleno =~ "lleno"

    assert {:ok, _} = GestorAlbergues.salida_albergue("laura", "A01", "1001")
    assert {:ok, _} = GestorAlbergues.ingreso_albergue("laura", "A01", "1003")
  end

  # ============================================================================
  # 6. PRUEBAS DE FAMILIARES, MENSAJES Y COINCIDENCIA DE MASCOTAS
  # ============================================================================
  test "historial de personas, mensajes y emparejamiento de mascotas sin doble cierre" do
    {:ok, _} = GestorUsuarios.conectar("laura", "1234", "Laura", :coordinador, "Z01")
    {:ok, _} = GestorZonas.registrar_zona(Node.self(), "laura", "Z01", "Zona Norte", :medio, 50)

    assert {:ok, _} = GestorFamiliares.reportar_persona("laura", "P01", "998877", "Andrés Pérez", 34, "Z01", :reportada)
    assert {:ok, p_act} = GestorFamiliares.cambiar_estado_persona("laura", "998877", :en_albergue)
    assert length(p_act.historial) == 1

    assert {:ok, _} = GestorFamiliares.enviar_mensaje("laura", "M01", "998877", "Estoy bien, escríbeme a familia@correo.com")
    assert {:ok, _} = GestorFamiliares.marcar_entregado("laura", "M01")
    assert {:error, _} = GestorFamiliares.marcar_entregado("laura", "M01")

    assert {:ok, _} = GestorMascotas.reportar_mascota("laura", "MP1", :perdida, "perro", "Luna", "collar rojo", "negra", "mediana", "Z01", "3001112233")
    assert {:ok, _} = GestorMascotas.reportar_mascota("laura", "ME1", :encontrada, "perro", "desconocido", "sin collar", "negra", "mediana", "Z01", "3009998877")

    assert {:ok, [{"MP1", "ME1", 90}]} = GestorMascotas.buscar_coincidencias()

    assert {:ok, _} = GestorMascotas.confirmar_coincidencia("laura", "MP1", "ME1")
    assert {:error, _} = GestorMascotas.confirmar_coincidencia("laura", "MP1", "ME1")
  end

  # ============================================================================
  # 7. PRUEBAS ESPECÍFICAS DEL PUNTO 1.4.9 (VALIDACIONES Y MANEJO DE ERRORES)
  # ============================================================================
  test "punto 1.4.9: cumplimiento de las 8 reglas de validación y manejo de errores" do
    {:ok, _} = GestorUsuarios.conectar("laura", "1234", "Laura", :coordinador, "Z01")
    {:ok, _} = GestorZonas.registrar_zona(Node.self(), "laura", "Z01", "Zona Centro", :critico, 100)

    # 1. Identificadores únicos
    assert {:error, _} = GestorZonas.registrar_zona(Node.self(), "laura", "Z01", "Duplicada", :alto, 10)
    assert {:ok, _} = GestorRecursos.registrar_recurso("laura", "R01", "Agua", :agua, 20, "litros", "Z01")
    assert {:error, _} = GestorRecursos.registrar_recurso("laura", "R01", "Otra Agua", :agua, 10, "litros", "Z01")
    assert {:ok, _} = GestorNecesidades.registrar_necesidad("laura", "N01", :agua, "Agua", 10, "Z01", :alta)
    assert {:error, _} = GestorNecesidades.registrar_necesidad("laura", "N01", :agua, "Dup", 5, "Z01", :alta)
    assert {:ok, _} = GestorAlbergues.registrar_albergue("laura", "A01", "Albergue 1", "Z01", 2)
    assert {:error, _} = GestorAlbergues.registrar_albergue("laura", "A01", "Albergue Dup", "Z01", 5)

    # 2. Cantidades y capacidades no negativas
    assert {:error, _} = GestorZonas.registrar_zona(Node.self(), "laura", "Z02", "Negativa", :bajo, -5)
    assert {:error, _} = GestorRecursos.registrar_recurso("laura", "R02", "Comida", :alimentos, -10, "cajas", "Z01")
    assert {:error, _} = GestorNecesidades.registrar_necesidad("laura", "N02", :agua, "Neg", -3, "Z01", :media)
    assert {:error, _} = GestorAlbergues.registrar_albergue("laura", "A02", "Cap Cero", "Z01", 0)
    assert {:error, _} = GestorAlbergues.registrar_albergue("laura", "A03", "Cap Neg", "Z01", -4)

    # 3. No asignar más recursos de los disponibles
    assert {:ok, _} = GestorNecesidades.registrar_necesidad("laura", "N03", :agua, "Mucha agua", 50, "Z01", :critica)
    assert {:error, msg_inv} = GestorNecesidades.asignar_recurso("laura", "N03", "R01", 50)
    assert msg_inv =~ "insuficiente"

    # 4. No superar capacidad máxima de albergue
    assert {:ok, _} = GestorAlbergues.ingreso_albergue("laura", "A01", "DOC1")
    assert {:ok, _} = GestorAlbergues.ingreso_albergue("laura", "A01", "DOC2")
    assert {:error, msg_cap} = GestorAlbergues.ingreso_albergue("laura", "A01", "DOC3")
    assert msg_cap =~ "lleno"

    # 5. No cerrar dos veces una necesidad o reporte
    assert {:ok, _} = GestorNecesidades.cambiar_estado("laura", "N01", :cancelada)
    assert {:error, _} = GestorNecesidades.cambiar_estado("laura", "N01", :cancelada)

    assert {:ok, _} = GestorMascotas.reportar_mascota("laura", "MP1", :perdida, "gato", "Michi", "blanco", "blanco", "pequeno", "Z01", "300111")
    assert {:ok, _} = GestorMascotas.reportar_mascota("laura", "ME1", :encontrada, "gato", "desconocido", "blanco", "blanco", "pequeno", "Z01", "300222")
    assert {:ok, _} = GestorMascotas.confirmar_coincidencia("laura", "MP1", "ME1")
    assert {:error, _} = GestorMascotas.confirmar_coincidencia("laura", "MP1", "ME1")

    # 6. Transiciones válidas de estado
    assert {:error, msg_trans} = GestorNecesidades.cambiar_estado("laura", "N03", :atendida)
    assert msg_trans =~ "Transición no permitida"

    # 7 y 8. Validación de entradas inválidas retornando {:error, _}
    assert {:error, _} = Zona.crear_zona("", "Sin código", :alto, 10)
    assert {:error, _} = Recurso.crear_recurso("R99", "", :agua, 10, "litros", "Z01")
    assert {:error, _} = PersonaAfectada.crear_afectada("P99", "", "Sin Doc", 20, "Z01", :reportada)
    assert {:error, _} = MensajeFamiliar.crear_mensaje("M99", "laura", "DOC1", "   ")
  end
end