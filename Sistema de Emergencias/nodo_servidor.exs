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
    # 1. Validamos que el nodo haya sido iniciado con --sname o --name
    if Node.self() == :nonode@nohost do
      Util.mostrar_error(
        "El nodo no está en modo distribuido (:nonode@nohost).\n" <>
          "Inícialo con: elixir --sname servidor --cookie emergencia nodo_servidor.exs"
      )
    else
      # 2. Registramos este proceso para poder enviarle :detener si es necesario
      Process.register(self(), __MODULE__)

      case SupervisorEmergencia.start_link() do
        {:ok, pid} ->
          Util.mostrar_mensaje("==========================================")
          Util.mostrar_mensaje("SupervisorEmergencia iniciado en #{inspect(pid)}")
          Util.mostrar_mensaje("8 GenServers activos bajo estrategia :one_for_one")
          Util.mostrar_mensaje("Nodo servidor #{Node.self()} listo y esperando clientes...")
          Util.mostrar_mensaje("==========================================")
          mantener_vivo(pid)

        {:error, razon} ->
          Util.mostrar_error("No se pudo iniciar el Supervisor: #{inspect(razon)}")
      end
    end
  end

  defp mantener_vivo(pid_supervisor) do
    receive do
      :detener ->
        Util.mostrar_mensaje("Deteniendo SupervisorEmergencia y cerrando servidor...")
        Supervisor.stop(pid_supervisor, :normal)
        :ok
    end
  end
end

NodoServidor.main()
