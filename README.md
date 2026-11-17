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

conectar laura 1234 "Laura Gomez" coordinadora centro
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

Para conectar varias terminales al mismo servidor al mismo tiempo en Windows, cada terminal debe tener un nombre de nodo distinto (--sname), pero todas deben usar exactamente la misma --cookie emergencia y apuntar a la carpeta del proyecto.Abre 4 ventanas o pestañas de PowerShell (todas dentro de C:\Users\USUARIO\Desktop\ProyectoFinalP3\Sistema de Emergencias) y ejecuta lo siguiente en cada una:  

 Terminal 1: Servidor Central Arranca primero esta ventana para que levante el SupervisorEmergencia y los 8 GenServer:
 elixir --sname servidor@localhost --cookie emergencia nodo_servidor.exs

Terminal 2: Cliente 1 — Laura (Coordinadora)Abre una segunda ventana de PowerShell y conéctala como cliente1:
elixir --sname cliente1@localhost --cookie emergencia nodo_cliente.exs
Dentro del menú del cliente:
conectar laura 1234 "Laura Gomez" coordinador centro
registrar_zona centro "Zona Centro" critico 300
registrar_zona zona_norte "Zona Norte" alto 150
registrar_albergue A01 "Albergue Norte" zona_norte 150
registrar_necesidad N001 agua 30 critica centro "Punto de atencion sector 3"
registrar_recurso R001 "Agua potable" agua 50 litros centro_acopio_1
ingreso_albergue A01 1094888111
asignar_recurso N001 R001 30



Terminal 3: Cliente 2 — Andrés (Segundo Coordinador para concurrencia)Abre una tercera ventana de PowerShell y conéctala como cliente2:
elixir --sname cliente2@localhost --cookie emergencia nodo_cliente.exs
Dentro del menú del cliente, pega:
conectar andres 5678 "Andres Lopez" coordinador centro
registrar_necesidad N002 agua 25 critica centro "Punto de atencion sector 4"
asignar_recurso N002 R001 25

Ejecuta asignar_recurso N001 R001 30 en la Terminal 2 y enseguida asignar_recurso N002 R001 25 en la Terminal 3 (una aprueba los 30 litros y la otra rechaza los 25 porque solo quedan 20 de 50).  

 Terminal 4: Cliente 3 — Carlos (Ciudadano) y Sofía (Voluntaria)Abre una cuarta ventana de PowerShell y conéctala como cliente3:
 elixir --sname cliente3@localhost --cookie emergencia nodo_cliente.exs
Dentro del menú del cliente, pega:
conectar carlos 1111 "Carlos Ruiz" ciudadano zona_norte
reportar_persona P001 1094888111 "Andres" 28 zona_norte localizada

hacer lo de ingresar albergue en la terminal 2 

enviar_mensaje M001 1094888111 "Hola Andres, estamos pendientes"
conectar sofia 2222 "Sofia Diaz" voluntario zona_norte
reportar_mascota MP01 perdida perro "Luna" "Collar rojo" negra mediana zona_norte 3001112233
reportar_mascota ME01 encontrada perro "desconocido" "Sin collar" negra mediana zona_norte 3104445566
buscar_coincidencias


Cierre y Resumen Final (Vuelve a la Terminal 2 — Laura)Con todas las terminales conectadas al mismo tiempo, en la Terminal 2 (donde sigue conectada Laura como coordinadora) ejecuta:   Plaintext
resumen
salir
(Y escribe salir en las Terminales 3 y 4 para desconectar a los demás usuarios).




