# Informe — LAB-01 · Bitácoras y auditoría del dato en PostgreSQL

**Estudiante:** `<Velazquez Espinoza Jose Fernando>` · **Matrícula:** `<16531711>`
**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos · Unidad III
**Fecha de ejecución:** 2026-11-07 UTC (2026-11-06, hora de Culiacán)

## 1. Despliegue y situación inicial

El servidor es una instalación nativa de PostgreSQL 16.15 con los paquetes de Ubuntu 24.04, administrado con `pg_ctlcluster`. La identificación se hizo desde el propio motor (`version()`, `data_directory`, `config_file`, `hba_file`), sin depender del sistema operativo. Las reglas `host` para `127.0.0.1` y `::1` estaban en `trust`: cualquier conexión TCP local entraba sin contraseña, y la bitácora nunca habría mostrado un acceso fallido ni podría distinguir a quien conoce la contraseña de quien solo escribe un nombre de usuario. Se cambiaron a `scram-sha-256`.

Por defecto, el servidor no registraba conexiones (`log_connections = off`) ni sentencias (`log_statement = none`); no tenía colector (`logging_collector = off`), así que el destino de la bitácora lo decidía el script de Ubuntu; y el prefijo `%m [%p] %q%u@%d` (modificado por el paquete) no incluía ni la aplicación ni la IP. Al reproducir el incidente (cambio del RFC de María García a `GAMA780912XXX`), la búsqueda en la bitácora devolvió **0 filas**: no podía responderse ninguna de las preguntas de Dirección. Ese cambio quedó como un hueco permanente, porque la auditoría no puede configurarse después del evento.

## 2. Configuración aplicada

Todos los cambios se hicieron con `ALTER SYSTEM`, que escribe en `postgresql.auto.conf` (prioridad sobre `postgresql.conf`), y se verificó el origen en `pg_settings.source` y `sourcefile`.

| Parámetro | Valor final | Aplicación | Justificación |
|---|---|---|---|
| `logging_collector` | on | **Reinicio** | El servidor administra su propia bitácora en `log/` y permite leerla con `pg_current_logfile()` y `pg_read_file()` en cualquier despliegue |
| `log_connections` | on | Recarga | Registra cada intento de conexión, exitoso o fallido, con origen y regla de `pg_hba.conf` |
| `log_disconnections` | on | Recarga | Registra el fin de cada sesión y su duración |
| `log_line_prefix` | `%m [%p] user=%u db=%d app=%a client=%h ` | Recarga | Sin usuario, base, aplicación e IP una línea dice qué pasó pero no quién ni desde dónde |
| `log_statement` | mod (primero ddl) | Recarga | Registra DDL, privilegios e INSERT/UPDATE/DELETE/TRUNCATE/COPY FROM sin el volumen y la exposición de datos de `all` |
| `log_min_error_statement` | error (por defecto) | — | Conserva la sentencia que provocó cada error |
| `shared_preload_libraries` | pgaudit | **Reinicio** | Parte C: carga la extensión al arrancar |
| `pgaudit.log` / `pgaudit.role` / `pgaudit.log_relation` | `role, ddl` / `auditor_datos` / on | Recarga | Parte C: registra lecturas y escrituras solo sobre `rfc` y `telefono` |

Se observaron dos detalles prácticos: la recarga es asíncrona (`pg_reload_conf()` solo envía la señal y la confirmación debe hacerse en una consulta posterior), y `pending_restart` no se activa hasta que el servidor relee la configuración. Adicionalmente se creó la vista `dba.bitacora` en un esquema sin acceso para `PUBLIC`.

## 3. Eventos observados

| Tipo | Ejemplo interpretado |
|---|---|
| Configuración | `03:12:31.133 [2952] LOG: parameter "log_statement" changed to "ddl"`. Lo escribe el proceso principal al recargar, no la sesión que lo pidió. Dice qué cambió y cuándo, pero no quién; el autor solo se conoce si la sentencia `ALTER SYSTEM` también quedó registrada, como ocurrió al pasar a `mod` (L53). |
| Acceso | `03:12:37.404 [3002] user=app_ventas ... client=127.0.0.1 FATAL: password authentication failed`, con `DETAIL` de la regla de `pg_hba.conf` (línea 125). Prueba que alguien desde 127.0.0.1 presentó el nombre `app_ventas` con una contraseña incorrecta, no que fuera la aplicación. Cada fallo aparece dos veces porque el cliente reintenta sin TLS. Con un rol inexistente, la bitácora añade `Role ... does not exist`, que el cliente no recibe. |
| Privilegio | `statement: GRANT UPDATE ON clientes TO app_ventas` (L41), con usuario `postgres` por socket local. `ddl` incluye `GRANT`, `REVOKE` y `CREATE ROLE`. |
| Estructura | `statement: ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20)` (L42). |
| Datos | `user=app_ventas app=app-ventas-web client=127.0.0.1 statement: UPDATE clientes SET telefono = '6679990000' WHERE id = 3` (L60). Con `ddl` el mismo tipo de sentencia no se registró (Actividad 7). |
| Error | `user=soporte_ana ERROR: permission denied for table clientes` seguido de `STATEMENT: DELETE FROM clientes WHERE id = 5` (L70–L71). Es un error de autorización: la sesión estaba autenticada, pero el rol no tenía el privilegio. |

`pg_stat_activity` mostró la sesión `reporte-mensual` de `soporte_ana` mientras existía (PID 3055). Al terminar, solo la bitácora conservó su conexión, su desconexión y la duración (20.031 s); el PID relaciona ambas fuentes.

## 4. Auditoría del dato

**Diseño.** La tabla `auditoria.cambios_clientes`, en un esquema sin acceso público, guarda por cada fila afectada: momento (`TIMESTAMPTZ`), `usuario_sesion`, `usuario_efectivo`, aplicación, IP, operación, `id_cliente` y la fila completa antes y después en JSONB. El JSONB conserva el estado completo aunque `clientes` cambie de estructura; la columna `segmento`, agregada después, apareció sin modificar la auditoría. La llena un disparador `AFTER INSERT OR UPDATE OR DELETE ... FOR EACH ROW`.

**`SECURITY DEFINER` y `search_path`.** La función se ejecuta con los privilegios de su propietario (`postgres`), así que `app_ventas` provoca la escritura en la auditoría sin tener acceso al esquema; se comprobó que no puede leerla ni borrarla (`permission denied for schema auditoria`). El `search_path` fijo (`pg_catalog, public`) impide que un usuario cree objetos con nombres iguales en otro esquema y logre que la función privilegiada los use. Además se revocó `EXECUTE` a `PUBLIC`, para que nadie pueda asociar esta función a una tabla propia y escribir eventos falsos.

**`session_user` frente a `current_user`.** En el incidente auditado (evento 1), `usuario_sesion = app_ventas` y `usuario_efectivo = postgres`. Dentro de una función `SECURITY DEFINER`, `current_user` es el propietario; solo `session_user` identifica a quien provocó el cambio.

**Resultado del incidente auditado.** El evento 1 responde todas las preguntas de Dirección sobre el cambio del RFC de María García: `app_ventas`, el 2026-11-07 a las 03:13:55.808 UTC (20:13 del 6-nov en Culiacán), desde 127.0.0.1, con `app-ventas-web`, de `GAMA780912XYZ` a `GAMA780912ZZZ`. La restauración es `UPDATE clientes SET rfc = 'GAMA780912XYZ' WHERE id = 3;`. El alta y baja de Pedro Ruiz quedó con la fila completa en los eventos 2 y 3, aunque el cliente ya no existe en `clientes`.

## 5. Limitaciones

**Lecturas.** Ni `mod` ni el disparador registran consultas. La lectura del RFC por `soporte_ana` solo dejó su conexión y desconexión. Las alternativas son `log_statement = all` (volumen y exposición), entregar el dato mediante una función que registre su uso, o pgaudit en modo objeto. Este último se probó en la Parte C: registró `SELECT nombre, rfc` y `SELECT *`, pero no `SELECT nombre, ciudad`, porque el rol `auditor_datos` solo tiene privilegios sobre `rfc` y `telefono`.

**Volumen.** Un `UPDATE` sin `WHERE` produjo 1 línea en la bitácora y 5 filas de auditoría, con dos JSONB cada una. Con un millón de clientes serían un millón de filas en la misma transacción, con su costo en tiempo, WAL y almacenamiento.

**Administrador con control total.** `postgres` desactivó el disparador, cambió el RFC a `GAMA780912GHI` y lo reactivó sin dejar evento de auditoría. La bitácora sí lo registró (L194–L196). Además, la discontinuidad entre el `valores_despues` del evento 1 y el `valores_antes` del evento 8 permite detectar el hueco desde la propia auditoría. Pero el mismo administrador podría cambiar `log_statement` a `none`, editar o borrar la bitácora, o desactivar pgaudit en su sesión. Ningún mecanismo dentro del servidor lo protege de quien lo controla; se requiere separación de funciones y custodia externa.

## 6. Riesgos de la bitácora

**Secretos expuestos.** `CREATE ROLE ... PASSWORD '...'` dejó la contraseña en texto claro en la bitácora, y eliminar el rol no la borró. Las contraseñas deben asignarse con `\password` (el servidor solo recibe el resumen SCRAM) o desde un gestor de secretos. Al exportar, el secreto se sustituyó dentro del servidor con `replace(...)` antes de escribir el archivo. Con `log_statement = all` también se registrarían datos personales usados en las consultas.

**Pérdida.** La bitácora vive en el servidor: se pierde si se reinstala o se recrea (en un contenedor, con el propio contenedor), y la vista `dba.bitacora` solo lee el archivo vigente, que rota por tamaño, por día y en cada reinicio. Al activar pgaudit, el reinicio inició un archivo nuevo; por eso se exportó antes.

**Acceso de terceros.** Quien lee la bitácora ve usuarios, IP, sentencias, y a veces secretos y datos personales. `pg_read_file` permite leer cualquier archivo accesible al servidor, por lo que debe quedarse en superusuarios o en un rol de auditoría controlado.

**Control de integridad (Actividad 16).** El archivo exportado `bitacora-lab01.log` tiene SHA-256 `9ca2aac586869eaf9f07cde47b8b26553a6d9a5853e119735ebb6361e392e42c`.

- *¿El hash impide modificar la bitácora?* No. Permite **demostrar** que el archivo no cambió desde que se calculó: cualquier modificación produce un resumen distinto.
- *¿Dónde guardarlo?* Fuera del alcance de quien podría modificar la bitácora: en el repositorio GitLab (con el historial de commits como sello de tiempo), en un sistema de otra área o en un registro de solo escritura. Si el hash está junto al archivo y bajo el mismo control, quien altera uno puede recalcular el otro.
- *Riesgos de conservarla solo en el servidor (NIST SP 800-92).* Un único punto de falla (disco, reinstalación, rotación); la posibilidad de que un atacante o un administrador con privilegios la altere o borre para ocultar sus acciones; la falta de correlación con otras fuentes; y la pérdida del hilo cronológico entre reinicios. La recomendación es enviarla a un repositorio central protegido.
- *Plazo de conservación propuesto.* Mínimo **12 meses** en línea y más tiempo en archivo protegido para lo relacionado con incidentes o cambios de datos personales. El criterio: muchos incidentes, como el reporte de facturación, se detectan semanas o meses después del evento, y la evidencia debe seguir existiendo cuando se necesite; además, los ciclos de auditoría y cierre fiscal suelen ser anuales. El límite superior lo fija la minimización de datos personales, porque la bitácora también los contiene. El plazo formal se define en el LAB-03.

## 7. Cronología y conclusión

La cronología completa (23 eventos con su fuente) está en `evidencias/15-cronologia.md`. En resumen, sobre el RFC de María García:

| Cambio | Quién | Valor anterior |
|---|---|---|
| A `GAMA780912XXX` (sin bitácora) | **No hay evidencia** | **No hay evidencia** |
| A `GAMA780912XYZ` (con `ddl`) | **No hay evidencia concluyente** (solo una sesión de `app_ventas` a las 03:12:47) | **No hay evidencia** |
| A `GAMA780912ZZZ` (con `mod` + disparador) | `app_ventas`, 127.0.0.1, `app-ventas-web`, 03:13:55.808 UTC | `GAMA780912XYZ` |
| A `GAMA780912GHI` (disparador desactivado) | `postgres`, socket local, 03:14:03.883 UTC (solo bitácora) | `GAMA780912ZZZ` (último estado auditado) |

**¿Con esta configuración puede demostrarse quién cambió un dato sensible y qué valor tenía antes?** Sí, para los usuarios que operan con privilegios ordinarios y siempre que la configuración estuviera activa **antes** del cambio. La bitácora con `mod` y un prefijo completo demuestra quién, cuándo, desde dónde y con qué sentencia; la auditoría con disparador demuestra el valor anterior y el nuevo de cada fila. Hay tres condiciones que esta configuración no resuelve: no registra lecturas (salvo con pgaudit); la identidad que demuestra es la del rol, de modo que una credencial compartida o robada no se distingue del titular; y no protege contra un administrador con control total, que puede desactivar ambos mecanismos. Para eso se necesita enviar la evidencia fuera del servidor, a la custodia de otra área.

## 8. Reflexión

**1. ¿Por qué la auditoría no puede configurarse después de un incidente?** Porque la evidencia se produce en el momento del evento o no se produce. Activar el registro después solo captura lo que viene; el cambio a `GAMA780912XXX` lo demostró.

**2. ¿Por qué conviene que la bitácora la administre el propio servidor?** Porque así se comporta igual en cualquier despliegue, se localiza y se lee desde el motor, su rotación es explícita, y no se pierde con la salida de un contenedor ni depende del script de arranque de cada distribución.

**3. ¿Por qué el prefijo de línea es tan importante como `log_statement`?** Porque una sentencia sin usuario, IP, aplicación ni PID no atribuye nada. El nivel decide *qué* se registra; el prefijo decide si puede responderse *quién*, *desde dónde* y en qué sesión.

**4. Diferencia práctica entre registrar la sentencia y registrar el cambio en el dato.** La sentencia muestra la intención y su autor (una línea, incluso para un millón de filas), pero no el valor anterior ni qué filas cambió. El registro del dato muestra el efecto fila por fila con antes y después, y permite restaurar. Se necesitan ambos.

**5. ¿Qué ofrece `pg_stat_activity` que no ofrece la bitácora, y viceversa?** `pg_stat_activity` muestra lo que ocurre **ahora**: estado, consulta en curso, tiempo de ejecución, esperas. Permite intervenir. La bitácora conserva lo que **ya ocurrió**, después de que la sesión terminó.

**6. ¿Quién audita al administrador?** Nadie, si toda la evidencia está bajo su control. Requiere que la bitácora salga del servidor hacia un sistema administrado por otra área; cuentas de administrador nominales y de uso excepcional; cambios a los mecanismos de auditoría con aprobación de un tercero; y una revisión periódica, independiente, de los eventos de configuración y de desactivación de controles.
