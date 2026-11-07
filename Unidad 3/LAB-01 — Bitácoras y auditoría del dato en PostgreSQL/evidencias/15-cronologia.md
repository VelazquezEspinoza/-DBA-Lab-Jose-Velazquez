# Evidencia 15 — Cronología y respuesta a Dirección (Actividad 17)

**Estudiante:** `<Nombre completo>` · **Matrícula:** `<Matrícula>`  
**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos · **Unidad III** · **LAB-01**  
**Servidor:** PostgreSQL 16.15 (Ubuntu 24.04, paquetes de la distribución) · base `comercial`  
**Ejecución:** 2026-11-07 UTC (2026-11-06 por la tarde-noche, hora de Culiacán, UTC−7)  
**Sesión de administrador:** `sudo -u postgres psql -d comercial` (socket local, método `peer`)  
Las contraseñas visibles se sustituyeron por `<REDACTED>`.

Fuentes: `evidencias/bitacora-lab01.log` (número de línea, “L”) y `auditoria.cambios_clientes` (“evt”). Horas en UTC del 2026-11-07; la hora local de Culiacán es UTC−7 (2026-11-06, a partir de las 20:12).

## Cronología

| # | Fecha y hora (UTC) | Usuario | Cliente | Tipo de evento | Qué ocurrió | ¿Exitoso? | Fuente |
|---|---|---|---|---|---|---|---|
| 1 | 03:12:17.670 | — (servidor) | — | Configuración | Arranque con `logging_collector = on`; inicia el archivo de bitácora | Sí | L1–L5 |
| — | **sin hora** | ? | ? | Datos | **Hueco:** RFC de María García cambia a `GAMA780912XXX` (Actividad 3). No se registró nada | — | Ninguna |
| 2 | 03:12:31.133 | — (proceso principal 2952) | — | Configuración | `log_connections`, `log_disconnections`, `log_line_prefix` y `log_statement = ddl` cambian. La sentencia que lo pidió no quedó registrada | Sí | L7–L10 |
| 3 | 03:12:37.404 | app_ventas | 127.0.0.1 | Acceso | Contraseña incorrecta (un intento con TLS y su reintento sin TLS) | No | L16, L19 |
| 4 | 03:12:37.443 | usuario_inexistente | 127.0.0.1 | Acceso | Autenticación con un rol que no existe | No | L22–L23, L26 |
| 5 | 03:12:37.486 | app_ventas | 127.0.0.1 | Acceso | Conexión autenticada (SCRAM) con `app-ventas-web` y su desconexión | Sí | L29–L32 |
| 6 | 03:12:41.554 | postgres | [local] | Privilegio | `REVOKE UPDATE ON clientes FROM soporte_ana` | Sí | L40 |
| 7 | 03:12:41.556 | postgres | [local] | Privilegio | `GRANT UPDATE ON clientes TO app_ventas` | Sí | L41 |
| 8 | 03:12:41.556 | postgres | [local] | Estructura | `ALTER TABLE clientes ADD COLUMN segmento` | Sí | L42 |
| 9 | 03:12:41.557 | postgres | [local] | Privilegio | `CREATE ROLE rol_temporal` con contraseña en texto claro (sustituida en la exportación) y `DROP ROLE` | Sí | L43–L44 |
| 10 | 03:12:47.006 | app_ventas | 127.0.0.1 | Acceso / Datos | Sesión de `app-ventas-web` (PID 3026). **Hueco:** con `ddl` no se registró la sentencia; el RFC pasó a `GAMA780912XYZ` | Sí (sesión) | L46–L49 |
| 11 | 03:12:47.038 | postgres | [local] | Configuración | `ALTER SYSTEM SET log_statement = 'mod'` y su aplicación | Sí | L53, L55 |
| 12 | 03:12:48.088 | app_ventas | 127.0.0.1 | Datos | `UPDATE clientes SET telefono = '6679990000' WHERE id = 3` | Sí | L60 |
| 13 | 03:12:52.438 | soporte_ana | 127.0.0.1 | Error | `DELETE FROM clientes WHERE id = 5`: permiso denegado | No | L69–L71 |
| 14 | 03:12:52.475 | postgres | [local] | Error | `DROP ROLE soporte_ana`: tiene privilegios dependientes | No | L76–L79 |
| 15 | 03:12:52.515 | soporte_ana | 127.0.0.1 | Acceso | Sesión `reporte-mensual` de 20 s; termina con conexión reiniciada por el cliente | Sí | L81–L93 |
| 16 | 03:13:46.558 | postgres | [local] | Estructura | Creación del esquema `auditoria`, la tabla, la función y el disparador | Sí | L105–L147 |
| 17 | 03:13:55.808 | app_ventas | 127.0.0.1 | Datos | RFC `GAMA780912XYZ` → `GAMA780912ZZZ` (id = 3) | Sí | L158 · evt 1 |
| 18 | 03:13:55.849 | app_ventas | 127.0.0.1 | Error | Intento de leer `auditoria.cambios_clientes`: permiso denegado | No | L163–L164 |
| 19 | 03:13:55.952 | postgres | [local] | Datos | Alta y baja de Pedro Ruiz (id = 6) | Sí | L177, L179 · evt 2, 3 |
| 20 | 03:14:03.835 | app_ventas | 127.0.0.1 | Error | Intento de borrar la auditoría y de desactivar el disparador | No | L184–L189 |
| 21 | 03:14:03.882 | postgres | [local] | Estructura / Datos | Desactiva el disparador, cambia RFC `GAMA780912ZZZ` → `GAMA780912GHI` y lo reactiva. Sin evento de auditoría | Sí | L194–L196 |
| 22 | 03:14:03.941 | soporte_ana | 127.0.0.1 | Acceso | Sesión en la que leyó nombre, RFC y teléfono. La lectura no quedó registrada | Sí | L198–L201 |
| 23 | 03:14:03.976 | postgres | [local] | Datos | `UPDATE clientes SET segmento = 'regular'`: 1 línea, 5 eventos | Sí | L205 · evt 4–8 |

## Respuestas a Dirección (solo con evidencia)

**1. ¿Quién cambió el RFC?**

- **Primera vez (Actividad 3, a `GAMA780912XXX`): No hay evidencia.** La bitácora no registraba conexiones ni sentencias y la auditoría no existía. El evento no tiene hora: es un hueco.
- **Actividad 7 (a `GAMA780912XYZ`): No hay evidencia concluyente.** Existe una sesión de `app_ventas` desde 127.0.0.1 con `app-ventas-web` a las 03:12:47.006 (PID 3026, L46–L49), pero con `log_statement = ddl` el `UPDATE` no quedó escrito. El evento 1 confirma que a las 03:13:55 el valor ya era `GAMA780912XYZ`, pero no quién lo puso. La sesión es un indicio, no una prueba.
- **Actividad 12 (a `GAMA780912ZZZ`): `app_ventas`**, a las 03:13:55.808 UTC, desde 127.0.0.1, con la aplicación declarada `app-ventas-web` (L158 y evt 1, `usuario_sesion = app_ventas`).
- **Actividad 14 (a `GAMA780912GHI`): `postgres`**, por socket local, a las 03:14:03.883 UTC (L195), con el disparador desactivado (L194, L196). No existe evento de auditoría; el cambio se detecta por la bitácora y por la discontinuidad entre los eventos 1 y 8 (evidencia 13).

**2. ¿Quién cambió el teléfono?** `app_ventas`, desde 127.0.0.1 con `app-ventas-web`, a las 03:12:48.088 UTC (L60), a `6679990000`. El valor anterior: **no hay evidencia** en el servidor, porque la auditoría de datos aún no existía y la bitácora solo registra la sentencia.

**3. ¿Hubo intentos de acceso fallidos? ¿De qué usuarios y desde dónde?** Sí, desde 127.0.0.1 a las 03:12:37: con el usuario `app_ventas` y contraseña incorrecta (L16, L19) y con `usuario_inexistente`, que no existe como rol (L22, L26). Cada uno aparece dos veces por el reintento sin TLS del cliente, de modo que corresponden a **un** intento de conexión por usuario. Fueron anteriores a los cambios de las Actividades 7, 12 y 14. Respecto al primer cambio (Actividad 3): **no hay evidencia** de si hubo intentos fallidos antes, porque las conexiones aún no se registraban.

**4. ¿Qué valor tenía el RFC antes de cada cambio?**

| Cambio | Valor anterior | Fuente |
|---|---|---|
| Actividad 3 | **No hay evidencia** en el servidor | — |
| Actividad 7 | **No hay evidencia** en el servidor | — |
| Actividad 12 | `GAMA780912XYZ` | evt 1, `valores_antes` |
| Actividad 14 | `GAMA780912ZZZ` (último estado auditado) | evt 1, `valores_despues`; el valor nuevo `GAMA780912GHI` en L195 y evt 8 |

**5. ¿Desde qué aplicación o equipo?** Los cambios de `app_ventas` se hicieron desde 127.0.0.1 con `application_name = app-ventas-web`; ese nombre lo declara el cliente, así que identifica la conexión, no garantiza que fuera la aplicación. Los cambios de `postgres` se hicieron desde el propio servidor por socket local (sin IP), con `psql`.
