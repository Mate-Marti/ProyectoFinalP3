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



















conectar laura 9999 "Laura Gomez" coordinador centro
conectar laura 1234 "Laura Gomez" coordinador centro
registrar_zona centro "Zona Centro" alto 100
registrar_zona zona_sur "Zona Sur" alto -100
registrar_zona zona_x "Zona X" altisimo 10
registrar_necesidad N001 agua 30 critica centro "Punto de atencion sector 3"
registrar_necesidad N002 agua -30 critica centro "cantidad negativa"
registrar_necesidad N003 agua 30 critica zona_inexistente "zona falsa"
registrar_necesidad N004 agua 30 urgentisima centro "prioridad falsa"
registrar_recurso R001 "Agua potable" agua 50 litros centro_acopio_1
registrar_recurso R002 "Arroz" alimentos -50 kg centro_acopio_1
registrar_recurso R003 "Arroz" alimentos 50 kg bodega_inexistente
asignar_recurso N001 agua 500
asignar_recurso N001 agua -5
asignar_recurso N001 agua 30
asignar_recurso N999 agua 5
transferir_recurso R001 centro_acopio_1 zona_norte 500
transferir_recurso R001 lugar_falso zona_norte 5
transferir_recurso R001 centro_acopio_1 destino_fantasma 5
estado_necesidad N001 atendida
estado_necesidad N001 volando
estado_necesidad N001 en_atencion
estado_necesidad N001 cancelada
asignar_recurso N001 agua 5
registrar_albergue A01 "Albergue Norte" zona_norte 150
registrar_albergue A02 "Albergue Sur" zona_norte -150
registrar_albergue A02 "Albergue Sur" zona_norte 0
registrar_albergue A02 "Albergue Sur" zona_inexistente 150
reportar_persona P001 1094888111 "Andres" 28 zona_norte localizada
reportar_persona P002 1094888111 "Otro Andres" 30 zona_norte localizada
reportar_persona P003 555 "Beto" -28 zona_norte localizada
reportar_persona P004 666 "Carlos" 28 zona_norte desaparecida
reportar_persona P005 777 "Diana" 28 zona_inexistente localizada
estado_persona 1094888111 reunificada
estado_persona 1094888111 xyz
ingreso_albergue A01 1094888111
ingreso_albergue A01 999-no-registrada
ingreso_albergue A-NO 1094888111
salida_albergue A01 999
registrar_albergue A04 "Albergue Pequeno" zona_norte 1
reportar_persona P010 2222 "Elena" 30 zona_norte localizada
reportar_persona P011 3333 "Felipe" 31 zona_norte localizada
ingreso_albergue A04 2222
ingreso_albergue A04 3333
ingreso_albergue A04 2222
enviar_mensaje M001 1094888111 "Hola Andres, estamos pendientes"
entregar_mensaje M001
entregar_mensaje M001
reportar_mascota MP01 perdida perro "Luna" "Collar rojo" negra mediana zona_norte 3001112233
reportar_mascota MP02 robada perro "Luna" "Collar rojo" negra mediana zona_norte 3001112233
reportar_mascota MP03 perdida perro "Luna" "Collar rojo" negra mediana zona_inexistente 3001112233
reportar_mascota MP04 perdida perro "Rex" "Collar azul" negra mediana zona_norte 3007778888
reportar_mascota MG01 encontrada gato "desconocido" "Sin collar" gris pequena zona_norte 3109990000
confirmar_mascota MP01 ME01
confirmar_mascota MP01 ME01
reportar_mascota MP05 perdida perro "Toby" "Collar verde" negra mediana zona_norte 3001230000
reportar_mascota MP06 perdida perro "Max" "Collar rojo" negra mediana zona_norte 3001230001
reportar_mascota MP07 perdida perro "Zeus" "Collar gris" negra mediana zona_norte 3001230002
confirmar_mascota MP04 MG01
confirmar_mascota MP05 MP06
confirmar_mascota MP07 MP07
conectar ciud 1 "Ciud" ciudadano centro
registrar_zona zona_ciud "Zona" bajo 1
desconectar
registrar_zona zona_sinsesion "Zona" bajo 1
conectar laura 1234
reportar_persona P050 5050 "Ana@Maria" 30 zona_norte localizada
salir