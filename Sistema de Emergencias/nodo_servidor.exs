Code.require_file("util.ex")
Code.require_file("usuario.exs")
Code.require_file("zona.exs")
Code.require_file("recurso.exs")
Code.require_file("necesidad.exs")
Code.require_file("albergue.exs")
Code.require_file("persona_afectada.exs")
Code.require_file("Mensaje_Familiar.exs")
Code.require_file("reporte_mascota.exs")
Code.require_file("persistencia.exs")
Code.require_file("gestores/gestor_persistencia.exs", __DIR__)
Code.require_file("gestores/gestor_usuarios.exs", __DIR__)
Code.require_file("gestores/gestor_zonas.exs", __DIR__)
Code.require_file("gestores/gestor_recursos.exs", __DIR__)
Code.require_file("gestores/gestor_necesidades.exs", __DIR__)
Code.require_file("gestores/gestor_albergues.exs", __DIR__)
Code.require_file("gestores/gestor_familiares.exs", __DIR__)
Code.require_file("gestores/gestor_mascotas.exs", __DIR__)
Code.require_file("supervisor_emergencia.exs", __DIR__)

defmodule NodoServidor do
  def main() do
    {:ok, pid} = SupervisorEmergencia.start_link()
    Util.mostrar_mensaje("SupervisorEmergencia iniciado en #{inspect(pid)}")
    Util.mostrar_mensaje("8 GenServers activos bajo estrategia :one_for_one")
    Util.mostrar_mensaje("Nodo servidor #{Node.self()} listo y esperando clientes...")
    mantener_vivo()
  end

  defp mantener_vivo() do
    receive do
      :detener -> :ok
    end
  end
end

NodoServidor.main()
