# Evidencia 05 — Accesos exitosos y fallidos (Actividad 5)

**Estudiante:** `<Nombre completo>` · **Matrícula:** `<Matrícula>`  
**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos · **Unidad III** · **LAB-01**  
**Servidor:** PostgreSQL 16.15 (Ubuntu 24.04, paquetes de la distribución) · base `comercial`  
**Ejecución:** 2026-11-07 UTC (2026-11-06 por la tarde-noche, hora de Culiacán, UTC−7)  
**Sesión de administrador:** `sudo -u postgres psql -d comercial` (socket local, método `peer`)  
Las contraseñas visibles se sustituyeron por `<REDACTED>`.

## Intentos de conexión por red

```text
$ psql "postgresql://app_ventas:incorrecta@127.0.0.1/comercial" -c "SELECT 1"
psql: error: connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "app_ventas"
connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "app_ventas"
$ psql "postgresql://usuario_inexistente:x@127.0.0.1/comercial" -c "SELECT 1"
psql: error: connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "usuario_inexistente"
connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "usuario_inexistente"
$ psql "postgresql://app_ventas:<REDACTED>@127.0.0.1/comercial?application_name=app-ventas-web" -c "SELECT count(*) FROM clientes"
 count
-------
     5
(1 row)
```

## Bitácora filtrada por cliente y conteo de fallos

```text
SELECT linea FROM dba.bitacora WHERE linea LIKE '%client=127.0.0.1%' ORDER BY num;
                                                                                                                                 linea
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-07 03:12:37.397 UTC [3002] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=38496
 2026-11-07 03:12:37.404 UTC [3002] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 FATAL:  password authentication failed for user "app_ventas"
 2026-11-07 03:12:37.404 UTC [3002] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 DETAIL:  Connection matched file "/etc/postgresql/16/main/pg_hba.conf" line 125: "host    all             all             127.0.0.1/32            scram-sha-256"
 2026-11-07 03:12:37.406 UTC [3003] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=38502
 2026-11-07 03:12:37.409 UTC [3003] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 FATAL:  password authentication failed for user "app_ventas"
 2026-11-07 03:12:37.409 UTC [3003] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 DETAIL:  Connection matched file "/etc/postgresql/16/main/pg_hba.conf" line 125: "host    all             all             127.0.0.1/32            scram-sha-256"
 2026-11-07 03:12:37.434 UTC [3006] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=38514
 2026-11-07 03:12:37.443 UTC [3006] user=usuario_inexistente db=comercial app=[unknown] client=127.0.0.1 FATAL:  password authentication failed for user "usuario_inexistente"
 2026-11-07 03:12:37.443 UTC [3006] user=usuario_inexistente db=comercial app=[unknown] client=127.0.0.1 DETAIL:  Role "usuario_inexistente" does not exist.
 2026-11-07 03:12:37.445 UTC [3007] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=38528
 2026-11-07 03:12:37.449 UTC [3007] user=usuario_inexistente db=comercial app=[unknown] client=127.0.0.1 FATAL:  password authentication failed for user "usuario_inexistente"
 2026-11-07 03:12:37.449 UTC [3007] user=usuario_inexistente db=comercial app=[unknown] client=127.0.0.1 DETAIL:  Role "usuario_inexistente" does not exist.
 2026-11-07 03:12:37.477 UTC [3010] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=38544
 2026-11-07 03:12:37.486 UTC [3010] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 LOG:  connection authenticated: identity="app_ventas" method=scram-sha-256 (/etc/postgresql/16/main/pg_hba.conf:125)
 2026-11-07 03:12:37.486 UTC [3010] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 LOG:  connection authorized: user=app_ventas database=comercial application_name=app-ventas-web SSL enabled (protocol=TLSv1.3, cipher=TLS_AES_256_GCM_SHA384, bits=256)
 2026-11-07 03:12:37.487 UTC [3010] user=app_ventas db=comercial app=app-ventas-web client=127.0.0.1 LOG:  disconnection: session time: 0:00:00.010 user=app_ventas database=comercial host=127.0.0.1 port=38544
(16 rows)

SELECT substring(linea from 'failed for user "([^"]+)"') AS usuario,
       substring(linea from 'client=(\S+)')               AS cliente,
       count(*)                                           AS intentos_fallidos,
       min(left(linea, 23))                               AS primero,
       max(left(linea, 23))                               AS ultimo
FROM dba.bitacora
WHERE linea LIKE '%FATAL:  password authentication failed%'
GROUP BY 1, 2
ORDER BY intentos_fallidos DESC;
       usuario       |  cliente  | intentos_fallidos |         primero         |         ultimo
---------------------+-----------+-------------------+-------------------------+-------------------------
 app_ventas          | 127.0.0.1 |                 2 | 2026-11-07 03:12:37.404 | 2026-11-07 03:12:37.409
 usuario_inexistente | 127.0.0.1 |                 2 | 2026-11-07 03:12:37.443 | 2026-11-07 03:12:37.449
(2 rows)
```

![Accesos fallidos y exitosos](capturas/05-accesos.png)

## Hallazgo propio: cada comando produjo dos intentos fallidos

Cada `psql` con contraseña incorrecta generó **dos** líneas `FATAL` con PID distintos (3002 y 3003; 3006 y 3007). El servidor de Ubuntu tiene SSL activado y el cliente usa `sslmode=prefer`: primero intenta con TLS; al fallar la autenticación, vuelve a intentar sin TLS. El mensaje del cliente también aparece dos veces. Al contar intentos de fuerza bruta hay que tenerlo en cuenta: 2 líneas no siempre son 2 acciones de una persona.

## 11.1 Lectura de una línea campo por campo

Línea: `2026-11-07 03:12:37.404 UTC [3002] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 FATAL:  password authentication failed for user "app_ventas"` y su `DETAIL`.

| Campo | Valor | Significado |
|---|---|---|
| Fecha y hora | 2026-11-07 03:12:37.404 UTC | Momento exacto con milisegundos, en UTC (20:12:37 del 6-nov en Culiacán) |
| PID | 3002 | Proceso que atendió ese intento; agrupa sus líneas (`connection received`, `FATAL`, `DETAIL`) |
| Usuario | app_ventas | Nombre de rol que **presentó** el cliente; no prueba que fuera la aplicación |
| Base de datos | comercial | Base solicitada en la conexión |
| Aplicación | [unknown] | La sesión no llegó a establecerse, aún no se había aplicado `application_name` |
| Cliente | 127.0.0.1 | Dirección de origen de la conexión TCP |
| Severidad | FATAL | Error que termina la sesión: la conexión fue rechazada |
| Mensaje | password authentication failed | La contraseña no coincide con el resumen SCRAM guardado |
| Regla aplicada | pg_hba.conf línea 125 | Regla `host all all 127.0.0.1/32 scram-sha-256` que exigió la contraseña |

## Respuestas

**1. ¿Prueba que la aplicación de ventas intentó entrar?** No. Prueba que *alguien*, desde `127.0.0.1`, a las 03:12:37 UTC, intentó autenticarse **con el nombre** `app_ventas` y una contraseña incorrecta. El nombre de usuario lo escribe el cliente. Puede haber sido la aplicación mal configurada, una persona probando credenciales o un ataque.

**2. ¿Qué información adicional registra cuando el rol no existe? ¿Por qué no la recibe el cliente?** En la bitácora aparece `DETAIL: Role "usuario_inexistente" does not exist.`; el cliente solo recibe el mismo `password authentication failed` que con un rol real. Así se evita la enumeración de usuarios: un atacante no puede distinguir “el usuario existe pero la contraseña es incorrecta” de “el usuario no existe”. El administrador sí necesita esa distinción para investigar.

**3. ¿Por qué `app=[unknown]` en el intento fallido y `app=app-ventas-web` en la desconexión?** `application_name` viaja en el paquete inicial, pero el proceso solo lo aplica como parámetro de la sesión **después** de autenticar y autorizar. Las líneas anteriores (`received`, `authenticated`, `authorized`, o el `FATAL`) se escriben antes; la desconexión ocurre con la sesión ya establecida. En la línea `connection authorized` el valor sí aparece dentro del mensaje (`application_name=app-ventas-web`).

**4. Patrón de fuerza bruta y consulta.** Muchas líneas `FATAL: password authentication failed` desde un mismo `client=` en poco tiempo; o un mismo origen probando muchos usuarios distintos (rociado de contraseñas); o fallos repetidos seguidos de un `connection authorized` exitoso desde la misma IP (la más grave). La consulta de conteo es la segunda del bloque anterior: agrupa por usuario y cliente, y muestra el primer y el último intento para medir la ventana de tiempo.
