# ProyectoFinalP3
Repositorio del proyecto final del curso de Programación 3.

Guía rápida para ejecutar y probar el sistema distribuido cliente-servidor.

Paso 1: Abrir la primera terminal e iniciar el Servidor
Abre una terminal ubicada en la carpeta raíz del proyecto (Sistema de Emergencias).

Pega y ejecuta el siguiente comando:
elixir --sname servidor@localhost --cookie emergencia nodo_servidor.exs

Verás que el servidor inicia el supervisor y los 8 procesos GenServer, mostrando el mensaje: "Nodo servidor servidor@localhost listo y esperando clientes..."

Deja esta terminal abierta sin escribir nada más en ella.

Paso 2: Abrir una segunda terminal e iniciar un Cliente
Abre una nueva terminal en la misma carpeta (Sistema de Emergencias).

Pega y ejecuta el siguiente comando:
elixir --sname cliente1@localhost --cookie emergencia nodo_cliente.exs

Si la conexión es exitosa, aparecerá el mensaje "Conectado exitosamente al nodo servidor@localhost" y verás el prompt [sin_sesion]> listo para recibir instrucciones.
(Nota: Si quieres probar varios usuarios conectados al mismo tiempo, abre una tercera terminal y ejecuta el mismo comando cambiando solo el nombre del cliente, por ejemplo: cliente2@localhost).

Paso 3: Usar el sistema y probar los comandos
Una vez dentro del cliente, escribe ayuda y presiona Enter para ver la lista completa de comandos disponibles y sus parámetros.

Recuerda que los textos con espacios (como nombres o descripciones) deben ir entre comillas dobles ("...").

Para cerrar la sesión y salir del cliente, escribe salir. Para apagar el servidor, presiona Ctrl + C dos veces en su terminal.

Ejemplo de comandos para probar todo el flujo
Ejecuta estos comandos uno por uno en la terminal del cliente para comprobar que todas las funciones y la persistencia funcionan correctamente:

conectar laura 1234 "Laura Gomez" coordinador centro
registrar_zona centro "Zona Centro" alto 100
registrar_necesidad N001 agua 30 critica centro "Punto de atencion sector 3"
registrar_recurso R001 "Agua potable" agua 50 litros centro_acopio_1
asignar_recurso N001 agua 30
registrar_albergue A01 "Albergue Norte" zona_norte 150
reportar_persona P001 1094888111 "Andres" 28 zona_norte localizada
ingreso_albergue A01 1094888111
enviar_mensaje M001 1094888111 "Hola Andres, estamos pendientes"
reportar_mascota MP01 perdida perro "Luna" "Collar rojo" negra mediana zona_norte 3001112233
reportar_mascota ME01 encontrada perro "desconocido" "Sin collar" negra mediana zona_norte 3104445566
buscar_coincidencias
resumen
salir